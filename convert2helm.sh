NS=$1
OW=$2
# generate output.yaml by running helm template skupper . > output.yaml
for object in  $(yq '(.kind, .metadata.name)' output.yaml | tr '\n' ' ' | sed -e 's/ \-\-\- /;/g' -e 's/ /\//g' -e 's/;/ /g' -e 's/\/$//g')
do
    oc label --overwrite=$OW $object app.kubernetes.io/managed-by=Helm -n $NS
    oc annotate --overwrite=$OW $object meta.helm.sh/release-name="skupper" -n $NS
    oc annotate --overwrite=$OW $object meta.helm.sh/release-namespace=$NS -n $NS
done