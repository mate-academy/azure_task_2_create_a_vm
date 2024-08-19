sudo mkdir /app 
exit
sudo apt install python3-pip
cd /app
sudo mv todoapp.service /etc/systemd/system/ 
sudo systemctl daemon-reload
sudo systemctl start todoapp
sudo systemctl enable todoapp
systemctl status todoapp
ll
start.sh
cd scripts
ll
cd ..
sudo nano start.sh
sudo apt-get install python3-venv
python3 -m venv /app/venv
source /app/venv/bin/activate
pip install -r /app/requirements.txt
chmod +x /app/start.sh
/app/start.sh
cd ..
/app/start.sh
dos2unix /app/start.sh
sudo apt-get update
sudo apt-get install -y dos2unix
dos2unix /app/start.sh
/app/start.sh
systemctl status todoapp
sudo systemctl daemon-reload
sudo systemctl start todoapp
sudo systemctl enable todoapp
systemctl status todoapp
pwsh
sudo snap install powershell
sudo snap install powershell -classic
sudo snap install powershell -c
sudo snap install powershell --classic
pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Connect-AzAccount -TenantId <your Microsoft Entra ID tenant id>
Connect-AzAccount -TenantId <your Microsoft Entra ID tenant id
pwsh
cd ~
sudo chmod -R 777 /app
pwsh
exit
pwsh
scp C:\Users\Serveladus\.ssh\id_rsa.pub xthecutter@azure-new-2.uksouth.cloudapp.azure.com:/home/xthecutter/
sudo scp C:\Users\Serveladus\.ssh\id_rsa.pub xthecutter@azure-new-2.uksouth.cloudapp.azure.com:/home/xthecutter/
exit
pwsh
exit
cd /app
ll
cd scripts
ll
cd ..
ll
pwsh
cd temp
xclip -sel clip < exported-template.json
cd ~
scp -r xthecutter@azure-new-2.uksouth.cloudapp.azure.com:/app D:/app
cd /.ssh
cd ~/.ssh
ls -la
sudo nano authorized_keys 
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
ssh -i C:/Users/Serveladus/.ssh/id_rsa xthecutter@azure-new-2.uksouth.cloudapp.azure.com
ssh -i C:/Users/Serveladus/.ssh/id_rsa.pub xthecutter@azure-new-2.uksouth.cloudapp.azure.com
ssh -i C:/Users/Serveladus/.ssh/id_rsa xthecutter@azure-new-2.uksouth.cloudapp.azure.com
ssh -i ~/.ssh/id_rsa xthecutter@azure-new-2.uksouth.cloudapp.azure.com
exit
scp -r xthecutter@azure-new-2.uksouth.cloudapp.azure.com:/app D:/app
chmod 600 ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBJBWs6h52TO/fGZRUrn5a4KNiT39eQSL0rVrc6bNtp43f1d0Tzuk0hupP10NHUUlHT2qr5kwEJ5VWlXStdm5ecZbp1aUDVNHM8NauNYiqYhSFyJbowXFCCuoRQKysWvkTR9lFZXywWfUCjKbYhZnfrYfyzGKV6I5mfRV5sBqalK9e9poRPJCU+BQ77ymNipnO5sx8tKgCyYLOqnTrr1WuEE9/HRjy+et4Uuo9kyRSY7eSKmmp+WekciLZfJWRX6h2nu0WQ6Etlw9drHUh7ghYG4QXA8qPgfDcPwyjap8inM2X7VeT0Wq6a5ws/JLm2wky4BnT9B3oacdXjvZ3BrDRmEY0It9k0maCYb8et7MOt/Ua5O80T6160OsvEH5oIss2PRLh/ECDRQ6W8+EVQZvtgpdswAtW7koKyIsSmI3rrSSGyhlTC9IrZC+KO5yb2AQvhSdYFk5IIcf7SvcxDl803yjP+KYBy8STd31AUPqjQ0SKIRgYAhEAKKOv1y59oOM= serveladus@Serveladus-PC" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
scp -r xthecutter@azure-new-2.uksouth.cloudapp.azure.com:/app D:/app
sudo reboot
