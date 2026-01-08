# MSF-ACE: Advanced Command-line Environment

**MSF-ACE** 是一个为开源Metasploit Framework设计的强大扩展插件，旨在通过纯命令行界面，提供许多Metasploit Pro版本的核心功能，如自动化工作流、项目管理和专业报告。

这个项目是为了那些热爱`msfconsole`的强大功能和灵活性，但又希望获得更高效率和自动化能力的渗透测试人员和安全研究员而生。

---

## ✨ 功能特性

*   **统一的命令入口**: 所有功能通过简洁的 `ace` 命令调用 (`ace <module> <action>`)。
*   **项目管理**: 创建、切换、列出和管理你的渗透测试项目，隔离不同目标的数据。 (`ace project ...`)
*   **自动化任务链 (开发中)**: 定义并执行一系列自动化任务，从扫描到利用，再到报告。 (`ace task ...`)
*   **专业报告 (开发中)**: 一键从你的项目数据生成专业的HTML或PDF报告。 (`ace report ...`)
*   **模块化设计**: 易于扩展，可以方便地添加新的功能模块。

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

执行以下命令创建链接：

```bash
# 确保目标插件目录存在
mkdir -p /root/.msf4/plugins

# 创建指向 src/ace.rb 的链接
ln -s /opt/metasploit-framework-ACE/src/ace.rb /root/.msf4/plugins/ace.rb

# 创建指向 src/ace/ 目录的链接
ln -s /opt/metasploit-framework-ACE/src/ace /root/.msf4/plugins/ace
```

### 步骤 3: 验证安装

启动Metasploit Framework。请确保以安装插件的目标用户身份启动（在此示例中为`root`）。

```bash
sudo msfconsole
```

在`msfconsole`提示符下，加载插件：

```
msf6 > load ace
[*] MSF-ACE: Advanced Command-line Environment
[*] ACE module 'Project' loaded.
[*] Successfully loaded plugin: MSF-ACE

msf6 >
```

看到成功加载的消息后，您就可以开始使用`ace`命令了！

```
msf6 > ace help
```

---

## 卸载

要卸载`MSF-ACE`，只需删除您在步骤2中创建的符号链接即可：

```bash
rm /root/.msf4/plugins/ace.rb
rm /root/.msf4/plugins/ace
```

这不会删除您克隆的源代码，只是解除了它与Metasploit的关联。
