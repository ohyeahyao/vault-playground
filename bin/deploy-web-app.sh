
helm upgrade --install web-app ./app/charts/web-app -f app/web-app/value.sit.yaml -n app
#helm upgrade --install web-app ./app/charts/web-app -f app/web-app/value.prod.yaml -n app