# EARL results for SHACL.

../script/tc --write-manifests -o manifests.ttl
../script/tc --earl -o earl.ttl
earl-report --format json -o earl.jsonld earl.ttl
earl-report --json --format html --template template.haml -o earl.html earl.jsonld
