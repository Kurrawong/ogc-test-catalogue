test="$(cat ontpub-compliance/test.sparql)"
for i in $(ls ontpub-compliance)
do
  query="$(cat ontpub-compliance/$i)"
  echo "Executing query:"
  echo $query
  echo "----------------"
  curl -d update="$query" -d 'output=text' http://localhost:3030/fuseki-ogc/update
  echo "----------------"
  sleep 2
done
