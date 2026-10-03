# Further improvements

**Private EC2 behind an ALB.** The EC2s currently sit in public subnets and nginx serves its own
self-signed certificate (as the brief asks). In a real environment:

- Move the EC2s into the private subnets and enable the NAT gateway for outbound traffic.
- Put an ALB with an ACM certificate in the public subnets, forwarding to nginx over HTTPS.
- Use SSM Session Manager or a CI runner inside the VPC for access, Ansible and Packer – no inbound
  admin ports and no manually created SSH key.

**Scaling.** Run the Packer AMI in an Auto Scaling Group instead of a single EC2 per OS.
