#!/usr/bin/bash
AUTH=23bc46b1-71f6-4ed5-8c54-816aa4f8c502:123zO3xZCLrMN6v2BKK1dXYFpXlPkccOFqm12CdAsMgRU4VrNZ9lyGVCGuMDGIwP
APIHOST=localhost:9999
FUNC=store-post
#wsk action delete $FUNC
#sleep 5
#wsk action create $FUNC --docker zyuxuan0115/sn-register-user
curl -u $AUTH "http://$APIHOST/api/v1/namespaces/_/actions/$FUNC?blocking=true&result=true" \
-X POST -H "Content-Type: application/json" \
-d '{"post_id":1723,"creator": {"user_id":11028,"username":"twenisch"},"req_id":7795,"text":"yesterday once more ","user_mentions": [],"media":[],"urls":[],"timestamp":12343249,"post_type":"POST"}'

curl -u $AUTH "http://$APIHOST/api/v1/namespaces/_/actions/$FUNC?blocking=true&result=true" \
-X POST -H "Content-Type: application/json" \
-d '{"post_id":1722,"creator": {"user_id":11028,"username":"twenisch"},"req_id":7796,"text":"thanks ","user_mentions": [],"media":[],"urls":[],"timestamp":12343251,"post_type":"POST"}'
