@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

rem Set variable values 
set subscription_id=24c73a41-f1d3-4ed2-8a5a-b2e359457574
set resource_group=Doc
set location=eastus
set expiry_date=2026-01-01T00:00:00Z

rem Get random numbers to create unique resource names
set unique_id=!random!!random!

rem Create a storage account in your Azure resource group 
echo Creating storage...
call az storage account create --name ai102form!unique_id! --subscription !subscription_id! --resource-group !resource_group! --location !location! --sku Standard_LRS --encryption-services blob --default-action Allow --allow-blob-public-access true --only-show-errors --output none

echo Uploading files...
rem Get storage key to create a container in the storage account 
for /f "tokens=*" %%a in (
  'az storage account keys list --subscription !subscription_id! --resource-group !resource_group! --account-name ai102form!unique_id! --query "[0].value" -o tsv'
) do (
  set AZURE_STORAGE_KEY=%%a
)
rem Create container 
call az storage container create --account-name ai102form!unique_id! --name sampleforms --public-access blob --auth-mode key --account-key %AZURE_STORAGE_KEY% --output none
rem Upload files from your local sampleforms folder to a container called sampleforms in the storage account
rem Each file is uploaded as a blob 
call az storage blob upload-batch -d sampleforms -s ./sample-forms --account-name ai102form!unique_id! --auth-mode key --account-key %AZURE_STORAGE_KEY%  --output none
rem Set a variable value for future use 
set STORAGE_ACCT_NAME=ai102form!unique_id!

rem Get a Shared Access Signature (a signed URI that points to one or more storage resources) for the blobs in sampleforms   
for /f "tokens=*" %%a in (
'az storage container generate-sas --account-name ai102form!unique_id! --name sampleforms --expiry !expiry_date! --permissions rwl'
) do (
set SAS_TOKEN=%%a
set SAS_TOKEN=!SAS_TOKEN:~1,-1!
)
set URI=https://!STORAGE_ACCT_NAME!.blob.core.windows.net/sampleforms?!SAS_TOKEN!

rem Print the generated Shared Access Signature URI, which is used by Azure Storage to authorize access to the storage resource
echo -------------------------------------
echo SAS URI: !URI!
