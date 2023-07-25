#!/bin/bash

 oc delete deploy skupper-site-controller
 oc delete route skupper
 #oc patch deploy/skupper-site-controller --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
 oc label deployment skupper-site-controller app.kubernetes.io/managed-by=Helm --overwrite 
 oc annotate deployment skupper-site-controller meta.helm.sh/release-name="skupper" --overwrite
 oc annotate deployment skupper-site-controller meta.helm.sh/release-namespace=$1 --overwrite


for object in  skupper-router skupper-service-controller skupper-site-controller
do
for resource in deployment/${object} rolebinding/${object} role/${object} sa/${object};

 do
    oc patch $resource --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
    oc label $resource app.kubernetes.io/managed-by=Helm --overwrite 
    oc annotate $resource meta.helm.sh/release-name="skupper" --overwrite
    oc annotate $resource meta.helm.sh/release-namespace=$1 --overwrite

done
done

for secrets in  skupper-console-users skupper-claims-server  skupper-site-server skupper-local-client skupper-console-certs skupper-local-server skupper-service-client

do
    oc patch secret/${secrets} --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
    oc label secret $secrets app.kubernetes.io/managed-by=Helm --overwrite 
    oc annotate secret  $secrets meta.helm.sh/release-name="skupper" --overwrite
    oc annotate secret $secrets meta.helm.sh/release-namespace=$1 --overwrite

done

for cm in skupper-site skupper-internal skupper-services 
do 
 oc patch cm/${cm} --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
 oc label cm $cm app.kubernetes.io/managed-by=Helm --overwrite 
 oc annotate cm $cm meta.helm.sh/release-name="skupper" --overwrite
 oc annotate cm $cm meta.helm.sh/release-namespace=$1 --overwrite
done


for routes in skupper  claims skupper-inter-router
do
 oc patch route/${routes} --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
 oc label route $routes app.kubernetes.io/managed-by=Helm --overwrite 
 oc annotate route $routes meta.helm.sh/release-name="skupper" --overwrite
 oc annotate route $routes meta.helm.sh/release-namespace=$1 --overwrite
done

for services in skupper skupper-router skupper-router-local
do 
 oc patch service/${services} --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]'
 oc label service $services app.kubernetes.io/managed-by=Helm --overwrite 
 oc annotate service $services meta.helm.sh/release-name="skupper" --overwrite
 oc annotate service $services meta.helm.sh/release-namespace=$1 --overwrite
done

