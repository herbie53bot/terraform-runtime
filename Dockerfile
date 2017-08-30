from python:2.7-jessie
run apt-get update && \
      apt-get -y install sudo unzip
run wget -P /tmp https://releases.hashicorp.com/terraform/0.8.8/terraform_0.8.8_linux_amd64.zip && \
      unzip /tmp/terraform_0.8.8_linux_amd64.zip && \
      chmod +x terraform && \
      mv terraform /usr/local/bin
run wget -O /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/v0.9.6/terragrunt_linux_amd64 && \
      chmod +x /usr/local/bin/terragrunt
add iac-requirements.txt /cm/requirements.txt
workdir /cm 
run addgroup --system --gid 981 herbie_bot && \
    adduser --system --uid 981 --gid 981 --home /home/herbie_bot herbie_bot
RUN echo "herbie_bot ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/herbie_bot && \
    chmod 0440 /etc/sudoers.d/herbie_bot
run wget -O /cm/terraform-provider-credstash_0.1.0 https://github.com/sspinc/terraform-provider-credstash/releases/download/v0.1.0/terraform-provider-credstash_linux_amd64 && \
    chmod +x /cm/terraform-provider-credstash_0.1.0
run echo 'providers {\n\
	credstash = "/cm/terraform-provider-credstash_0.1.0"\n\
}\n'\
	> /home/herbie_bot/.terraformrc
user herbie_bot
workdir /home/herbie_bot
run sudo pip install -r /cm/requirements.txt


