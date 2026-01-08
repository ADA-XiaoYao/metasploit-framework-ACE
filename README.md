# MSF-ACE: Advanced Command-line Environment

**MSF-ACE** 是一个为开源Metasploit Framework设计的强大扩展插件，旨在通过纯命令行界面，提供许多Metasploit Pro版本的核心功能，如自动化工作流、项目管理、凭证重用和专业报告。

这个项目是为了那些热爱`msfconsole`的强大功能和灵活性，但又希望获得更高效率和自动化能力的渗透测试人员和安全研究员而生。

---

## ✨ 功能特性

*   **统一的命令入口**: 所有功能通过简洁的 `ace` 命令调用 (`ace <module> <action>`)。
*   **项目管理**: 隔离不同目标的测试数据 (`ace project ...`)。
*   **自动化任务链**: 通过YAML文件定义和执行复杂的测试流程 (`ace task ...`)。
*   **凭证重用**: 一键尝试使用已获取的凭证进行横向移动 (`ace creds pivot`)。
*   **简化网络跳板**: 轻松通过已有会话建立内网路由 (`ace pivot setup`)。
*   **Web快速扫描**: 封装常用模块，一键进行初步Web探测 (`ace web scan`)。
*   **团队协作基础**: 支持用户管理，为审计和协作打下基础 (`ace team ...`)。
*   **专业报告**: 一键从项目数据生成专业的HTML报告 (`ace report generate`)。

---

## 🚀 安装指南

安装`MSF-ACE`非常简单，只需将源代码克隆到本地，然后将其链接到Metasploit的插件目录即可。

以下步骤以在`root`用户环境下安装为例。如果您希望为其他用户（如`kali`）安装，只需将路径中的`/root/`替换为该用户的家目录（如`/home/kali/`）。

### 步骤 1: 克隆仓库

首先，打开终端，使用`git`克隆本项目到您选择的任意位置（例如，`/opt/`目录是一个不错的选择，用于存放第三方工具）。

```bash
git clone https://github.com/ADA-XiaoYao/metasploit-framework-ACE.git /opt/metasploit-framework-ACE
```

### 步骤 2: 创建符号链接

接下来，我们需要在Metasploit的插件目录中创建一个指向我们源代码的符号链接（Symbolic Link）。这样做的好处是，未来您只需要在`/opt/metasploit-framework-ACE`目录中更新代码（例如通过`git pull`），Metasploit就会自动加载最新的版本，无需重复复制文件。

```bash
# 确保目标插件目录存在
sudo mkdir -p /root/.msf4/plugins

# 链接主文件和模块目录
sudo ln -s /opt/metasploit-framework-ACE/src/ace.rb /root/.msf4/plugins/ace.rb
sudo ln -s /opt/metasploit-framework-ACE/src/ace /root/.msf4/plugins/ace
```

### 步骤 3: 启动与加载

启动Metasploit Framework。请确保以安装插件的目标用户身份启动（在此示例中为`root`）。

```bash
sudo msfconsole
```

在`msfconsole`提示符下，加载插件：

```
msf6 > load ace
[*] MSF-ACE: Advanced Command-line Environment
[*] ACE 'ace_users' table not found, creating it...
[*] Table 'ace_users' created successfully.
[*] ACE module 'Team' loaded.
... (其他模块加载信息) ...
[*] Successfully loaded plugin: MSF-ACE
```

看到成功加载的消息后，您就可以开始使用了！输入 `ace help` 查看所有可用模块。

---

## 📖 使用方法 (Workflow)

`MSF-ACE`旨在将一次完整的渗透测试流程化、自动化。以下是一个典型的使用工作流：

### 第1步: 项目准备

在开始测试前，为你的目标创建一个独立的项目，并添加操作员信息。

```
# 创建一个新项目，所有后续数据都将保存在这里
msf6 > ace project create corp_xyz_pentest

# (可选) 添加团队成员用于记录
msf6 > ace team adduser your_name
```

### 第2步: 自动化扫描

使用`ace task`模块来自动化执行初步的信息收集和漏洞扫描。

首先，在`~/.msf4/ace_tasks/`目录下创建一个任务文件，例如`scan.yml`:
```yaml
name: "Initial Network Recon"
vars:
  RHOSTS: "192.168.1.0/24"
steps:
  - name: "Nmap Scan for common web and SMB ports"
    command: "db_nmap -sV -p 80,443,445 {{RHOSTS}}"
  - name: "Scan for MS17-010 if SMB is found"
    run_if:
      conditions:
        - model: services
          where: "port = 445"
    command: "use auxiliary/scanner/smb/smb_ms17_010; set RHOSTS -R; run"
```

然后，在`msfconsole`中执行这个任务，并可以在运行时覆盖目标地址：
```
msf6 > ace task run scan.yml --vars "RHOSTS=10.10.10.0/24"
```
`MSF-ACE`会自动完成扫描，并根据发现的服务智能地执行后续步骤。

### 第3步: 深入渗透与横向移动

当自动化扫描发现突破口后，使用更高级的`ace`命令进行深入测试。

*   **快速Web探测**: 发现一个Web服务 `http://10.10.10.80`？
    ```
    msf6 > ace web scan http://10.10.10.80
    ```

*   **建立内网跳板**: 成功利用漏洞并获得一个会话 (Session 1)？用它来建立内网路由。
    ```
    msf6 > ace pivot setup 1
    ```
    现在，你可以通过这个跳板对内网进行扫描。

*   **自动凭证重用**: 在测试中获取到了一些密码？让`MSF-ACE`自动尝试用它们登录网络中的所有其他主机。
    ```
    msf6 > ace creds pivot
    ```

### 第4步: 生成报告

测试结束，所有数据都已存入数据库。现在，一键生成专业的HTML报告。

```
msf6 > ace report generate --output /home/kali/corp_xyz_report.html
```
用浏览器打开生成的HTML文件，即可看到本次测试的完整成果，包括主机列表、漏洞详情和捕获的凭证。

---

## 卸载

要卸载`MSF-ACE`，只需删除您在安装步骤中创建的符号链接即可：

```bash
sudo rm /root/.msf4/plugins/ace.rb
sudo rm /root/.msf4/plugins/ace
```
