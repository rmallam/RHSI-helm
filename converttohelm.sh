#!/bin/bash

NAMESPACE=$1
if [ -z "$NAMESPACE" ] 
then
    NAMESPACE=`oc project --short`
    echo "Using current ns $NAMESPACE"
fi
echo "Using current ns $NAMESPACE"
convert()
    {   
        echo "patching the $resource"
        resource=$1 
        oc patch $resource --type json --patch '[{ "op": "remove", "path": "/metadata/ownerReferences" }]' -n $NAMESPACE
        oc label $resource app.kubernetes.io/managed-by=Helm --overwrite -n $NAMESPACE
        oc annotate $resource meta.helm.sh/release-name="skupper" --overwrite -n $NAMESPACE
        oc annotate $resource meta.helm.sh/release-namespace=$NAMESPACE --overwrite -n $NAMESPACE
    }

secrets=(skupper-console-users skupper-claims-server  skupper-site-server skupper-local-client skupper-console-certs skupper-local-server skupper-service-client)
for secret in "${secrets[@]}"
    do
        resource="secret/${secret}"
        convert $resource
    done


cm=(skupper-site skupper-internal skupper-services  prometheus-server-config)
for cm in "${cm[@]}"
    do 
        resource="cm/${cm}"
        convert $resource
    done

routes=(skupper claims skupper-inter-router)
for routes in "${routes[@]}"
do
        resource="route/${routes}"
        convert $resource
done

services=(skupper skupper-router skupper-router-local skupper-prometheus)
for services in "${services[@]}"
do 
        resource="service/${services}"
        convert $resource
done


for object in  skupper-router skupper-service-controller skupper-site-controller skupper-prometheus
    do
        for resource in deployment/${object} rolebinding/${object} role/${object} sa/${object};
        do
            convert $resource
        done
done

oc delete deploy skupper-site-controller
oc delete deploy skupper-service-controller
oc delete route skupper