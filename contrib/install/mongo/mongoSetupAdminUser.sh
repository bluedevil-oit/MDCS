#!/usr/bin/env bash

mongo  --port=$MDCS_MONGO_PORT <<EOF
use admin
db.createUser(
{
  user: "${MDCS_MONGO_ADMIN_USER}",
  pwd: "${MDCS_MONGO_ADMIN_PWD}",
  roles: [ { role: "userAdminAnyDatabase", db: "admin"},"backup","restore"]
  }
)
EOF