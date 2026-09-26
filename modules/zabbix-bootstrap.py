import json
import os
import secrets
import socket
import time
import urllib.error
import urllib.request

API_URL = "http://127.0.0.1:8081/api_jsonrpc.php"
API_HOST = "zabbix.local"
PASSWORD_FILE = "/root/zabbix-admin-password"
ACTION_NAME = "Register Linux servers"
GROUP_NAME = "Linux servers"
TEMPLATE_NAME = "Linux by Zabbix agent active"
SERVER_TEMPLATE_NAME = "Zabbix server health"
LEGACY_SERVER_HOST = "Zabbix server"

opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))


class ApiError(RuntimeError):
    pass


def api(method, params, token=None):
    headers = {
        "Content-Type": "application/json-rpc",
        "Host": API_HOST,
    }
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1,
    }
    if token:
        payload["auth"] = token

    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode(),
        headers=headers,
    )

    try:
        with opener.open(request, timeout=10) as response:
            result = json.load(response)
    except (OSError, urllib.error.URLError) as error:
        raise ApiError(str(error)) from error

    if "error" in result:
        error = result["error"]
        details = error.get("data", "")
        raise ApiError(
            f"{error['code']}: {error['message']} {details}"
        )
    return result["result"]


def login(password):
    try:
        return api("user.login", {
            "username": "Admin",
            "password": password,
        })
    except ApiError:
        return None


def read_or_create_password():
    try:
        descriptor = os.open(
            PASSWORD_FILE,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL,
            0o600,
        )
    except FileExistsError:
        pass
    else:
        with os.fdopen(descriptor, "w") as password_file:
            password_file.write(secrets.token_urlsafe(32) + "\n")

    os.chmod(PASSWORD_FILE, 0o600)
    with open(PASSWORD_FILE, encoding="utf-8") as password_file:
        return password_file.read().strip()


def authenticate(password):
    for _ in range(60):
        token = login(password)
        if token:
            return token

        default_token = login("zabbix")
        if default_token:
            users = api("user.get", {
                "output": ["userid"],
                "filter": {"username": ["Admin"]},
            }, default_token)
            api("user.update", {
                "userid": users[0]["userid"],
                "passwd": password,
            }, default_token)
            token = login(password)
            if token:
                return token

        time.sleep(2)

    raise RuntimeError("Unable to authenticate with the Zabbix API")


def ensure_host_group(token):
    groups = api("hostgroup.get", {
        "output": ["groupid"],
        "filter": {"name": [GROUP_NAME]},
    }, token)
    if groups:
        return groups[0]["groupid"]

    result = api("hostgroup.create", {"name": GROUP_NAME}, token)
    return result["groupids"][0]


def get_template_id(token, name):
    templates = api("template.get", {
        "output": ["templateid"],
        "filter": {"host": [name]},
    }, token)
    if not templates:
        raise RuntimeError(f"Zabbix template not found: {name}")
    return templates[0]["templateid"]


def ensure_server_host(token, group_id, template_ids):
    hostname = socket.gethostname()
    hosts = api("host.get", {
        "output": ["hostid", "host"],
        "filter": {"host": [hostname, LEGACY_SERVER_HOST]},
        "selectGroups": ["groupid"],
        "selectParentTemplates": ["templateid"],
    }, token)
    server_host = next(
        (host for host in hosts if host["host"] == hostname),
        None,
    )
    legacy_host = next(
        (host for host in hosts if host["host"] == LEGACY_SERVER_HOST),
        None,
    )

    if server_host:
        groups = {group["groupid"] for group in server_host["groups"]}
        groups.add(group_id)
        templates = {
            template["templateid"]
            for template in server_host["parentTemplates"]
        }
        templates.update(template_ids)
        api("host.update", {
            "hostid": server_host["hostid"],
            "groups": [{"groupid": group} for group in sorted(groups)],
            "templates": [
                {"templateid": template}
                for template in sorted(templates)
            ],
        }, token)
    else:
        if legacy_host:
            api("host.delete", [legacy_host["hostid"]], token)
            legacy_host = None
        api("host.create", {
            "host": hostname,
            "name": hostname,
            "groups": [{"groupid": group_id}],
            "interfaces": [{
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": "127.0.0.1",
                "dns": "",
                "port": "10050",
            }],
            "templates": [
                {"templateid": template}
                for template in template_ids
            ],
        }, token)

    if legacy_host:
        api("host.delete", [legacy_host["hostid"]], token)


def ensure_registration_action(token, group_id, template_id):
    action = {
        "name": ACTION_NAME,
        "eventsource": 2,
        "status": 0,
        "filter": {
            "evaltype": 0,
            "conditions": [{
                "conditiontype": 24,
                "operator": 2,
                "value": "Linux",
            }],
        },
        "operations": [
            {"operationtype": 2},
            {
                "operationtype": 4,
                "opgroup": [{"groupid": group_id}],
            },
            {
                "operationtype": 6,
                "optemplate": [{"templateid": template_id}],
            },
        ],
    }

    actions = api("action.get", {
        "output": ["actionid"],
        "eventsource": 2,
        "filter": {"name": [ACTION_NAME]},
    }, token)
    if actions:
        action["actionid"] = actions[0]["actionid"]
        del action["eventsource"]
        api("action.update", action, token)
    else:
        api("action.create", action, token)


def main():
    password = read_or_create_password()
    token = authenticate(password)
    group_id = ensure_host_group(token)
    template_id = get_template_id(token, TEMPLATE_NAME)
    server_template_id = get_template_id(token, SERVER_TEMPLATE_NAME)
    ensure_server_host(
        token,
        group_id,
        [template_id, server_template_id],
    )
    ensure_registration_action(token, group_id, template_id)
    print("Zabbix auto-registration bootstrap complete")


if __name__ == "__main__":
    main()
