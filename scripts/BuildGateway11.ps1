param($BlobStorageUrl, $CertPwd, $GatewayVersion)

# Install VS2017 build tools for C++
md -Path c:\tmp -Force
pushd c:\tmp
$Url = 'https://aka.ms/vs/15/release/vs_buildtools.exe'
$Exe = "vs_buildtools.exe"
$Dest = "c:\\tmp\\" + $Exe
$client = new-object System.Net.WebClient
$client.DownloadFile($Url,$Dest)
$Params = "--quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --norestart"
Start-Process $Dest -ArgumentList $Params -Wait
Remove-Item $Dest
   
# Get AzCopy
curl.exe -L -o AzCopy.zip https://aka.ms/downloadazcopy-v10-windows
Expand-Archive ./AzCopy.zip ./AzCopy -Force
md c:\AzCopy
Get-ChildItem ./AzCopy/*/azcopy.exe | Move-Item -Destination "C:\AzCopy\AzCopy.exe"

# Download gateway source packages
C:\AzCopy\AzCopy.exe login --identity
$iconnectgwUrl = $BlobStorageUrl + "gateway/iconnectgw.zip"
C:\AzCopy\AzCopy.exe copy $iconnectgwUrl .
Expand-Archive ./iconnectgw.zip ./iconnectgw -Force
$emrgwUrl = $BlobStorageUrl + "gateway/emrgw.zip"
C:\AzCopy\AzCopy.exe copy $emrgwUrl .
Expand-Archive ./emrgw.zip ./emrgw -Force
$gatewaykeyscalersolutionUrl = $BlobStorageUrl + "gateway/gatewaykeyscalersolution.zip"
C:\AzCopy\AzCopy.exe copy $gatewaykeyscalersolutionUrl .
Expand-Archive ./gatewaykeyscalersolution.zip ./gatewaykeyscalersolution -Force
$uiUrl = $BlobStorageUrl + "gateway/UI.zip"
C:\AzCopy\AzCopy.exe copy $uiUrl .
$gadUrl = $BlobStorageUrl + "gateway/GAD.zip"
C:\AzCopy\AzCopy.exe copy $gadUrl .

#Download WixToolset 3.11
curl.exe -L -o wix311.exe https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe
Start-Process -FilePath ./wix311.exe -ArgumentList /quiet -NoNewWindow -Wait

#curl.exe -L -o NDP471-KB4033342-x86-x64-AllOS-ENU.exe https://download.microsoft.com/download/9/E/6/9E63300C-0941-4B45-A0EC-0008F96DD480/NDP471-KB4033342-x86-x64-AllOS-ENU.exe
#Copy-Item -Path .\NDP471-KB4033342-x86-x64-AllOS-ENU.exe .\emrgw\emrgw\EMR_Setup\SetupEMR\Resources
#Copy-Item -Path .\NDP471-KB4033342-x86-x64-AllOS-ENU.exe .\iconnectgw\iconnectgw\GatewaySetup_1.1\POC\SetupPOC\Resources
#Copy-Item -Path .\NDP471-KB4033342-x86-x64-AllOS-ENU.exe .\iconnectgw\iconnectgw\GatewaySetup_1.1\COBAS\SetupCOBAS\Resources

# Build gateway

md -Path .\Artifacts -Force
md -Path .\Artifacts\UIapp -Force
md -Path .\Artifacts\GADapp -Force
Copy-Item -Path UI.zip -Destination .\Artifacts\UIapp -Force
Copy-Item -Path GAD.zip -Destination .\Artifacts\GADapp -Force

$MSBuild = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"

pushd .\gatewaykeyscalersolution\gatewaykeyscalersolution
& $MSBuild /property:Configuration=Release .\KeyScalerSolution\SecurityLibSrc\SecurityLib.sln
Copy-Item -Path .\KeyScalerSolution\SecurityLibSrc\Release\SecurityLib.dll -Destination ..\..\emrgw\emrgw\EMR_Setup\EMR_Application\Resources\underWin\ -Force
Copy-Item -Path .\KeyScalerSolution\SecurityLibSrc\Release\SecurityLib.dll -Destination ..\..\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_Application\Dependence\underBinFolder\ -Force
& $MSBuild /property:Configuration=Release .\KeyScalerSolution\KeyScalerSetup\Clients\wiprosample\WiproSample\Wipro.sln
Copy-Item -Path .\KeyScalerSolution\KeyScalerSetup\Clients\wiprosample\WiproSample\bin\Win32\Release\WiproSample.dll -Destination ..\..\emrgw\emrgw\EMR_Setup\EMR_Application\Resources\underWin\ -Force
Copy-Item -Path .\KeyScalerSolution\KeyScalerSetup\Clients\wiprosample\WiproSample\bin\Win32\Release\WiproSample.dll -Destination ..\..\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_Application\Dependence\underBinFolder\ -Force
popd


pushd .\emrgw\emrgw
& $MSBuild /property:Configuration=Release .\DBImportExportTool\ImportExport.sln
Copy-Item -Path .\EMR_Setup\EMR_Application\Resources\DBImportExportTool -Destination ..\..\Artifacts\importexportexe -Recurse -Force
& $MSBuild /property:Configuration=Release .\EMRGW\Build\EMRGW.sln
Copy-Item -Path .\EMRGW\Src\BIN -Destination ..\..\Artifacts\EMRGWbin -Recurse -Force
& $MSBuild /property:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=FolderProfile .\EMRGW/Src/EMRDB/EMRDB.csproj
Copy-Item -Path .\EMRGW\Src\EMRDB\bin -Destination ..\..\Artifacts\EMRDBbin -Recurse -Force
Copy-Item -Path .\EMRGW\Src\EMRDB\bin\x86 -Destination .\EMR_Setup\EMR_Application\Resources\WebAPI\bin -Recurse -Force
Copy-Item -Path .\EMRGW\Src\EMRDB\bin\x64 -Destination .\EMR_Setup\EMR_Application\Resources\WebAPI\bin -Recurse -Force
popd

pushd .\iconnectgw\iconnectgw
certutil.exe -f -user -p $CertPwd -importpfx ".\certificates\DigicertCodeSigningCrt.pfx"  Noroot
certutil.exe -store My

Copy-Item -Path .\IConnectGW\GatewaySetup\CredentialManager\Resources\credentialmanager-win32_uat.conf -Destination .\IConnectGW\GatewaySetup\CredentialManager\Resources\credentialmanager-win32.conf -Force
Copy-Item -Path .\IConnectGW\GatewaySetup\KeyScalar\Resources\wipro_uat.cfg .\IConnectGW\GatewaySetup\KeyScalar\Resources\wipro.cfg -Force
Copy-Item -Path .\IConnectGW_WebUI\gw_web_UAT.json .\IConnectGW_WebUI\gw_web.json -Force

& $MSBuild /property:Configuration=Release .\GatewaySetup_1.1\Version\Version.sln
& $MSBuild /property:Configuration=Release .\GatewaySetup_1.1\Uninstaller\Uninstaller.sln
Copy-Item -Path .\GatewaySetup_1.1\Uninstaller\Uninstaller\bin -Destination ..\..\Artifacts\Uninstaller -Recurse -Force
& $MSBuild /property:Configuration=Release .\StartStopRVA\StartStopRVA.sln
Copy-Item -Path .\StartStopRVA\StartStopRVA\bin\* -Destination IConnectGW_WebUI\Server\StartStopRVA\ -Recurse -Force
& $MSBuild /property:Configuration=Release .\RestartGateway\RestartGWSvc.sln
Copy-Item -Path .\RestartGateway\BIN\* -Destination .\IConnectGW_WebUI\Server\RestartGWSvc\bin\ -Recurse -Force
& $MSBuild /property:Configuration=Release .\IConnectGW\Build\IConnectGW.sln
Copy-Item -Path .\IConnectGW\src\BIN -Destination ..\..\Artifacts\IConnectGWbin -Recurse -Force
Copy-Item -Path .\IConnectGW_WebUI\* -Destination .\IConnectGW\GatewaySetup\IConnectGW_WebUI\Dependence\IConnectGW_WebUI\ -Recurse -Force
Copy-Item -Path ..\..\Artifacts\UIapp -Destination .\IConnectGW\GatewaySetup\IConnectGW_Application\Dependence\underBinFolder -Recurse -Force
Copy-Item -Path ..\..\Artifacts\GADapp -Destination .\IConnectGW\GatewaySetup\IConnectGW_Application\Dependence\underBinFolder -Recurse -Force
& $MSBuild /property:Configuration=Release /p:RunWixToolsOutOfProc=true .\IConnectGW\GatewaySetup\GatewaySetup.sln
Copy-Item -Path .\IConnectGW\GatewaySetup\KeyScalar\bin\release -Destination ..\..\Artifacts\Keyscalar_msi -Recurse -Force
Copy-Item -Path .\IConnectGW\GatewaySetup\CredentialManager\bin\release -Destination ..\..\Artifacts\CredentialManager_msi -Recurse -Force
Copy-Item -Path .\IConnectGW\GatewaySetup\IConnectGW_Application\bin\release -Destination ..\..\Artifacts\IConnectGW_Application_msi -Recurse -Force
Copy-Item -Path .\IConnectGW\GatewaySetup\IConnectGW_WebUI\bin\release -Destination ..\..\Artifacts\IConnectGW_WebUI.msi -Recurse -Force
& $MSBuild /property:Configuration=Release .\UpdateAgentWS\SUApp\SUApp.sln
& $MSBuild /property:Configuration=Release .\UpdateAgentWS\UpdateAgentWS.sln
popd

Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_Application\bin\release\IConnectGW_Application.msi -Destination .\emrgw\emrgw\EMR_Setup\SetupEMR\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\KeyScalar\bin\release\KeyScalar.msi -Destination .\emrgw\emrgw\EMR_Setup\SetupEMR\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\CredentialManager\bin\release\CredentialManager.msi -Destination .\emrgw\emrgw\EMR_Setup\SetupEMR\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_WebUI\bin\release\IConnectGW_WebUI.msi -Destination .\emrgw\emrgw\EMR_Setup\SetupEMR\Resources\ -Force

Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_Application\bin\release\IConnectGW_Application.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\POC\SetupPOC\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\KeyScalar\bin\release\KeyScalar.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\POC\SetupPOC\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\CredentialManager\bin\release\CredentialManager.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\POC\SetupPOC\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_WebUI\bin\release\IConnectGW_WebUI.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\POC\SetupPOC\Resources\ -Force

Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_Application\bin\release\IConnectGW_Application.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\COBAS\SetupCOBAS\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\KeyScalar\bin\release\KeyScalar.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\COBAS\SetupCOBAS\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\CredentialManager\bin\release\CredentialManager.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\COBAS\SetupCOBAS\Resources\ -Force
Copy-Item -Path .\iconnectgw\iconnectgw\IConnectGW\GatewaySetup\IConnectGW_WebUI\bin\release\IConnectGW_WebUI.msi -Destination .\iconnectgw\iconnectgw\GatewaySetup_1.1\COBAS\SetupCOBAS\Resources\ -Force

pushd .\emrgw\emrgw
& $MSBuild /property:Configuration=Release .\EMR_Setup\EMR.sln
Copy-Item -Path .\EMR_Setup\SetupEMR\bin -Destination ..\..\Artifacts\EMRGWapplication_exe -Recurse -Force
Copy-Item -Path .\EMR_Setup\package.json -Destination ..\..\Artifacts\package-json-emr -Recurse -Force
Copy-Item -Path .\EMRGW\Src\EMRConfig -Destination ..\..\Artifacts\EMRconfig -Recurse -Force
popd

pushd .\iconnectgw\iconnectgw
& $MSBuild /property:Configuration=Release /p:RunWixToolsOutOfProc=true .\GatewaySetup_1.1\POC\POC.sln
Copy-Item -Path .\GatewaySetup_1.1\POC\SetupPOC\bin\release\ -Destination ..\..\Artifacts\GWapplicationPOC-exe -Recurse -Force
& $MSBuild /property:Configuration=Release /p:RunWixToolsOutOfProc=true .\GatewaySetup_1.1\COBAS\COBAS.sln
Copy-Item -Path .\GatewaySetup_1.1\COBAS\SetupCOBAS\bin\release\ -Destination ..\..\Artifacts\GWapplicationCobas-exe -Recurse -Force
& $MSBuild /property:Configuration=Release /p:RunWixToolsOutOfProc=true .\UpdateAgentWS\AUInstaller\AUInstaller.sln
Copy-Item -Path .\UpdateAgentWS\AUInstaller\AUInstallerEXE\bin\release\ -Destination ..\..\Artifacts\Auinstallerexe -Recurse -Force
Copy-Item -Path .\UpdateAgentWS\AUInstaller\Installer\bin\release\ -Destination ..\..\Artifacts\Installer-exe -Recurse -Force
Copy-Item -Path .\GatewaySetup_1.1\Json -Destination ..\..\Artifacts\package-json -Recurse -Force
popd

# Deployment

mkdir Output/poc/resources -Force
mkdir Output/dms/resources -Force
mkdir Output/emr/resources -Force

Copy-Item -Path .\Artifacts\Auinstallerexe\AUApplication.exe -Destination .\Output\poc\resources -Force
Copy-Item -Path .\Artifacts\GWapplicationPOC-exe\GWApplication.exe -Destination .\Output\poc\resources -Force
Copy-Item -Path .\Artifacts\package-json\POC\package.json -Destination .\Output\poc\resources -Force
Copy-Item -Path .\Artifacts\Installer-exe\Installer.exe -Destination .\Output\poc -Force
Copy-Item -Path .\Artifacts\Uninstaller\Release\Uninstaller.exe -Destination .\Output\poc -Force
pushd .\Output
Compress-Archive -Path .\poc\* -DestinationPath .\POC.zip -Force
popd

Copy-Item -Path .\Artifacts\Auinstallerexe\AUApplication.exe -Destination .\Output\emr\resources -Force
Copy-Item -Path .\Artifacts\EMRGWapplication_exe\Release\EMRGWApplication.exe -Destination .\Output\emr\resources -Force
Copy-Item -Path .\Artifacts\package-json-emr -Destination .\Output\emr\resources\package.json -Force
Copy-Item -Path .\Artifacts\Installer-exe\Installer.exe -Destination .\Output\emr -Force
Copy-Item -Path .\Artifacts\Uninstaller\Release\Uninstaller.exe -Destination .\Output\emr -Force
pushd .\Output
Compress-Archive -Path .\emr\* -DestinationPath .\EMR.zip -Force
popd

Copy-Item -Path .\Artifacts\Auinstallerexe\AUApplication.exe -Destination .\Output\dms\resources -Force
Copy-Item -Path .\Artifacts\GWapplicationCobas-exe\GWApplication.exe -Destination .\Output\dms\resources -Force
Copy-Item -Path .\Artifacts\package-json\DMS\package.json -Destination .\Output\dms\resources -Force
Copy-Item -Path .\Artifacts\Installer-exe\Installer.exe -Destination .\Output\dms -Force
Copy-Item -Path .\Artifacts\Uninstaller\Release\Uninstaller.exe -Destination .\Output\dms -Force
pushd .\Output
Compress-Archive -Path .\dms\* -DestinationPath .\DMS.zip -Force
popd

certutil.exe -hashfile ".\Output\POC.zip" SHA256 > ".\Output\hashvalue_POC.txt"
certutil.exe -hashfile ".\Output\DMS.zip" SHA256 > ".\Output\hashvalue_DMS.txt"
certutil.exe -hashfile ".\Output\EMR.zip" SHA256 > ".\Output\hashvalue_EMR.txt"

pushd .\Output
Compress-Archive -Path ..\Artifacts\EMRconfig\* -DestinationPath .\emrconfig.zip -Force
popd

$date = $(Get-Date -UFormat "%Y%m%d");
$version = $GatewayVersion
$driverInstallerContainer = $BlobStorageUrl + "driverinstaller"
$poczipStorageUrl = $driverInstallerContainer + "/poc/" + $date + "/" + $version + "/POC.zip"
$pochashStorageUrl = $driverInstallerContainer + "/poc/" + $date + "/" + $version + "/hashvalue_POC.txt"
$emrzipStorageUrl = $driverInstallerContainer + "/emr/" + $date + "/" + $version + "/EMR.zip"
$emrhashStorageUrl = $driverInstallerContainer + "/emr/" + $date + "/" + $version + "/hashvalue_EMR.txt"
$dmszipStorageUrl = $driverInstallerContainer + "/dms/" + $date + "/" + $version + "/DMS.zip"
$dmshashStorageUrl = $driverInstallerContainer + "/dms/" + $date + "/" + $version + "/hashvalue_DMS.txt"
$emrconfigStorageUrl = $driverInstallerContainer + "/emrconfig/" + $date + "/" + $version + "/emrconfig.zip"

C:\AzCopy\AzCopy.exe make $driverInstallerContainer
C:\AzCopy\AzCopy.exe copy .\Output\POC.zip $poczipStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\hashvalue_POC.txt $pochashStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\EMR.zip $emrzipStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\hashvalue_EMR.txt $emrhashStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\DMS.zip $dmszipStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\hashvalue_DMS.txt $dmshashStorageUrl
C:\AzCopy\AzCopy.exe copy .\Output\emrconfig.zip $emrconfigStorageUrl

popd