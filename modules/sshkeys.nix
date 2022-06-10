rec {
  ctr.kraken = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6T197GdZhXEOgZwCs334z5fWEteFL51r3/DSFwHRW+v5udKpuaaZs8tAAGz6ehPXtp9pAIa0vxBBJ4Nc4ZfNEwqLnXxnZvutS833lEWniiStKZJB9TF89HBEUTHYc+mlT90UNK8f3+OQzrHknap1eUZ7PhWYQkSbo86ccdkHZm0HqB6VbqJe5eM7WgFWa6FbpR3BohoGh48WbuYpGmW5oO2jOo9mCrlTR1bW4XLa4kjGjHAC0lDhUOf0uz9SH/tNEgvsjvZE4xRBM/UJZPO6FCl4BmxuWyHciGujtGS/Wrubj1buQaSHZgaNJcNT+B3T5MEQlkbLIm2mQT8Z6+YAJ ctr@kraken";

  ctr.lemur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiJJ7dNvh+0JLcxE+jIFap1NH/eg26JCEJKKVQqZ6Qf ctr@lemur";

  ctr.morgoth = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjIfvWL+16Q/Ubt/C7gmbSy0xIfCj+h51ky0/Ifs/mF ctr@morgoth";

  ctr.prometheus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNIenXh2DLheaGMtM4+gZNeeC1p02MC5EfpVoPizxXH ctr@prometheus";

  personal = [ ctr.lemur ctr.morgoth ctr.prometheus ];
}
