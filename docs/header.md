# 📋 Documentação Terraform

Este documento foi gerado automaticamente pelo [terraform-docs](https://github.com/terraform-docs/terraform-docs).

## 📦 Módulo: `{{ .Module.Name }}`

**Descrição:** {{ .Module.Header }}

---

## 📝 Sumário
<!-- TOC -->
- [📋 Documentação Terraform](#-documentação-terraform)
- [📦 Módulo: `{{ .Module.Name }}`](#-módulo-)
- [📝 Sumário](#-sumário)
- [🏗️ Arquitetura](#️-arquitetura)
- [⚙️ Inputs](#️-inputs)
- [📤 Outputs](#-outputs)
- [🔧 Recursos](#-recursos)
<!-- /TOC -->

---

## 🏗️ Arquitetura

```mermaid
graph TD
    A[Inputs] --> B[Módulo Terraform]
    B --> C[Outputs]
    B --> D[Recursos AWS/Azure/GCP]
