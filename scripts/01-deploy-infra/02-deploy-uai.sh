#!/bin/bash

if [ ! -z $USERNAME_UAMI ]
then
	echo "Create User-Assigned Identity"
	az deployment group create --subscription "$SUBSCRIPTION_ID" -n "UAMI-""$LOCATION" --verbose \
		-g "$RG_NAME_SECURITY" --template-uri "$TEMPLATE_UAMI" \
		--parameters \
		location="$LOCATION" \
		tenantId="$TENANT_ID" \
		identityName="$USERNAME_UAMI"

	#Debug
	#identityResourceId="$(az identity show --subscription ""$SUBSCRIPTION_ID"" -g ""$RG_NAME_SECURITY"" --name ""$USERNAME_UAMI"" -o tsv --query 'id')"
	#echo $identityResourceId
fi
