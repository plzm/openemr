#!/bin/bash

az group create --subscription "$SUBSCRIPTION_ID" -n "$RG_NAME_SECURITY" -l "$LOCATION" --verbose
az group create --subscription "$SUBSCRIPTION_ID" -n "$RG_NAME_GALLERY" -l "$LOCATION" --verbose
az group create --subscription "$SUBSCRIPTION_ID" -n "$RG_NAME_NET" -l "$LOCATION" --verbose
