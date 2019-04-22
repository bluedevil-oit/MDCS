#!/usr/bin/env bash
mongo --port $MDCS_MONGO_PORT -u $MDCS_MONGO_ADMIN_USER -p $MDCS_MONGO_ADMIN_PWD --authenticationDatabase admin <<EOF
use admin
db.createUser(
{
  user: "${MDCS_MONGO_OWNER_USER}",
  pwd: "${MDCS_MONGO_OWNER_PWD}",
  roles: [ { role: "dbOwner", db: "mgi"} ]
  }
)
use mgi
db.createUser({
  "user": "${MDCS_MONGO_OWNER_USER}",
  "pwd": "${MDCS_MONGO_OWNER_PWD}",
  "roles":["readWrite"]
})
EOF
