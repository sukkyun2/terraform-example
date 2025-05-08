## 📁 구조
```shell
terraform-study/
├── main.tf
├── variables.tf
└── modules/
    ├── network/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    ├── service/
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    │
    └── database/
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

## 📦 모듈 구성
### 🔌 network
- VPC
- Public & Private Subnets
- Internet Gateway
- NAT Gateway
- Security Groups
- Route Tables
- Subnet Route Table Associations

### 🚀 service
- Application Load Balancer (ALB)
- Target Group
- EC2 Instances

### 🛢 database
- RDS

## 🔗 아키텍처
- ![tf drawio](https://github.com/user-attachments/assets/21fa1dd8-2ddd-4b80-9f1f-56cee5f0ef65)  
- ![tf-페이지-2 drawio](https://github.com/user-attachments/assets/555bd0df-e1a8-4d42-b7fe-84185d0bbba3)


