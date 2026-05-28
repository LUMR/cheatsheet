# Claude Code Auto Mode 配置速查表

Auto mode 让 Claude Code 无需权限提示即可运行——每次工具调用都经过分类器（classifier），它会阻止任何不可逆、破坏性或超出环境范围的操作。通过 `autoMode` 配置块告诉分类器你的组织信任哪些仓库、存储桶和域名。

## 配置读取位置

分类器从以下位置读取 `autoMode` 配置：

| 范围 | 文件 | 用途 |
| --- | --- | --- |
| 单个开发者 | `~/.claude/settings.json` | 个人信任的基础设施 |
| 单个项目、单个开发者 | `.claude/settings.local.json` | 项目级信任的存储桶/服务，加入 gitignore |
| 组织级别 | Managed settings | 分发给所有开发者的信任基础设施 |
| `--settings` 参数或 Agent SDK | 内联 JSON | 自动化场景的每次调用覆盖 |

> 分类器**不会**读取 `.claude/settings.json`（共享项目设置），防止仓库注入自己的 allow 规则。

各作用域的条目会合并。开发者可以扩展 `environment`、`allow`、`soft_deny`、`hard_deny`，但无法删除 managed settings 提供的条目。

---

## autoMode 配置字段一览

| 字段 | 作用 | 格式 |
| --- | --- | --- |
| `environment` | 定义信任的基础设施（仓库、存储桶、域名） | 自然语言字符串数组 |
| `allow` | 覆盖 `soft_deny` 的例外规则 | 自然语言字符串数组 |
| `soft_deny` | 破坏性操作的阻止规则，可被 allow 或用户意图覆盖 | 自然语言字符串数组 |
| `hard_deny` | 无条件安全边界，不可被任何规则覆盖 | 自然语言字符串数组 |

---

## 规则优先级（从高到低）

```
hard_deny  >  soft_deny  >  allow  >  用户显式意图
```

| 层级 | 说明 |
| --- | --- |
| `hard_deny` | 无条件阻止，用户意图和 allow 例外均不生效 |
| `soft_deny` | 阻止破坏性操作，但用户意图和 allow 例外可覆盖 |
| `allow` | 作为 `soft_deny` 的例外，覆盖匹配的 soft_deny 规则 |
| 显式用户意图 | 用户消息直接、具体地描述了 Claude 即将执行的操作，可覆盖剩余的 soft_deny |

> 模糊请求不算显式意图。"清理仓库"不会授权 force-push，但"force-push 这个分支"会。

---

## environment — 定义信任基础设施

默认只信任当前工作目录和仓库的 remote。使用 `"$defaults"` 保留默认条目：

```json
{
  "autoMode": {
    "environment": [
      "$defaults",
      "Source control: github.example.com/acme-corp and all repos under it",
      "Trusted cloud buckets: s3://acme-build-artifacts, gs://acme-ml-datasets",
      "Trusted internal domains: *.corp.example.com, api.internal.example.com",
      "Key internal services: Jenkins at ci.example.com, Artifactory at artifacts.example.com"
    ]
  }
}
```

### environment 应覆盖的内容

| 类别 | 示例 |
| --- | --- |
| 组织信息 | 公司名、主要用途（软件开发、基础设施自动化、数据工程） |
| 源代码管理 | GitHub/GitLab/Bitbucket 组织 |
| 云提供商和信任存储桶 | `s3://acme-builds`、`gs://acme-datasets` |
| 信任的内部域名 | `*.internal.example.com`、`api.example.com` |
| 关键内部服务 | Jenkins、Artifactory、内部包索引等 |
| 额外上下文 | 合规要求、多租户基础设施、受监管行业约束 |

### 模板

```json
{
  "autoMode": {
    "environment": [
      "$defaults",
      "Organization: {公司名}. Primary use: {主要用途}",
      "Source control: {源码管理地址}",
      "Cloud provider(s): {云提供商}",
      "Trusted cloud buckets: {信任的存储桶}",
      "Trusted internal domains: {信任的域名}",
      "Key internal services: {关键服务}",
      "Additional context: {额外上下文}"
    ]
  }
}
```

> 条目用**自然语言**编写（不是正则或工具模式）。写得像给新工程师描述你的基础设施一样。描述越具体，分类器越能区分日常内部操作和数据外泄尝试。

---

## allow / soft_deny / hard_deny — 覆盖默认规则

每个字段都是自然语言字符串数组。使用 `"$defaults"` 保留内置规则：

```json
{
  "autoMode": {
    "environment": [
      "$defaults",
      "Source control: github.example.com/acme-corp and all repos under it"
    ],
    "allow": [
      "$defaults",
      "Deploying to the staging namespace is allowed: staging is isolated from production and resets nightly",
      "Writing to s3://acme-scratch/ is allowed: ephemeral bucket with a 7-day lifecycle policy"
    ],
    "soft_deny": [
      "$defaults",
      "Never run database migrations outside the migrations CLI, even against dev databases",
      "Never modify files under infra/terraform/prod/: production infrastructure changes go through the review workflow"
    ],
    "hard_deny": [
      "$defaults",
      "Never send repository contents to third-party code-review APIs"
    ]
  }
}
```

### 何时添加自定义规则

| 场景 | 操作 |
| --- | --- |
| 分类器反复误拦常规操作 | 添加到 `allow` |
| 你的环境有特定的破坏性风险 | 添加到 `soft_deny` |
| 绝不可越过的安全红线 | 添加到 `hard_deny` |

> 各字段独立评估，只设置 `environment` 不会影响默认的 `allow`/`soft_deny`/`hard_deny` 列表。只有想完全接管某个列表时才省略 `"$defaults"`。

---

## CLI 检查命令

| 命令 | 说明 |
| --- | --- |
| `claude auto-mode defaults` | 打印内置的 environment/allow/soft_deny/hard_deny 规则（JSON） |
| `claude auto-mode config` | 打印分类器实际使用的有效配置（合并了你的设置和默认值） |
| `claude auto-mode critique` | 用 AI 审查自定义规则，标记模糊、冗余或可能误判的条目 |

### 工作流

```bash
# 1. 查看默认规则
claude auto-mode defaults

# 2. 保存设置后，验证生效配置
claude auto-mode config

# 3. 审查自定义规则质量
claude auto-mode critique

# 4. 如需修改内置规则而非追加：导出默认规则 → 编辑 → 粘贴到设置文件（替换 $defaults）
```

---

## 拒绝记录与重试

- 拒绝记录在 `/permissions` 的 **Recently denied** 标签页中
- 按 `r` 可将拒绝操作标记为重试——退出对话框后 Claude 会重新发送该工具调用
- 同一目标反复被拒绝 → 将该目标添加到 `autoMode.environment`

### 程序化处理拒绝

使用 `PermissionDenied` hook 可编程响应拒绝事件。

---

## 渐进式上线建议

| 阶段 | 操作 |
| --- | --- |
| 起步 | 使用默认配置 + 添加源码管理组织和关键内部服务 |
| 第二步 | 添加信任域名和云存储桶 |
| 持续优化 | 遇到误拦时逐步补充，不需要一开始填满所有字段 |
