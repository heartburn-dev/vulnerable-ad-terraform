# Terraforming the Home Active Directory Lab from the Practical Ethical Hacking course by TCM Security

This is a small project that took far longer than I'd expected it to. Learning just a small amount of DevOps has seriously made me appreciate the skill that DevOps engineers must have - Kudos! 

This repository should spin up an Active Directory Home Lab in Azure with access available on a whitelisted-IP basis using SSH through a jump box. From there, a DC (HYDRA-DC) and two workstations are added, THE-PUNISHER and QUEENS.

For details setup instructions, please refer to my blog post on the topic.

## Installation

If you know what you're doing, the following steps will suffice. If not, refer to my blog post above.

```bash
git clone https://github.com/heartburn-dev/vulnerable-ad-terraform.git
cd vulnerable-ad-terraform/Terraform 
terraform init 
terraform apply 
```

Enter your public IPv4 address - This will be whitelisted for access. Then type yes. It generally takes about 15 minutes to spin up.

## References

These guys did the leg work, I just tried to muddle together to get it to work for me! Check their hard work out!

[Soumyadeep Basu](https://sbasu7241.medium.com/auror-project-challenge-1-automated-active-directory-lab-deployment-53e323445f4d)

[Chvancooten](https://github.com/chvancooten/CloudLabsAD)