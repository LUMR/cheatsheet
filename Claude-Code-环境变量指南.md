# Claude Code 第三方网关环境变量配置指南

> 参考来源：[code.claude.com/docs/en/env-vars](https://code.claude.com/docs/en/env-vars)

## 目录

- [必备配置](#必备配置)
- [兼容性修复](#兼容性修复)
- [功能增强](#功能增强)
- [平台特定配置](#平台特定配置)
- [通用配置示例](#通用配置示例)

---

## 必备配置

使用第三方网关时必须设置的变量。

| 变量 | 说明 | 示例 |
|------|------|------|
| `ANTHROPIC_BASE_URL` | 覆盖 API 端点，将请求路由到代理或网关。设置为非官方地址时，MCP 工具搜索默认禁用 | `https://your-gateway.example.com/v1` |
| `ANTHROPIC_API_KEY` | API 密钥，作为 `X-Api-Key` 头发送。设置后将替代 Claude Pro/Max/Team/Enterprise 订阅认证 | `sk-your-api-key` |

---

## 兼容性修复

网关报错时按需设置。不报错则无需配置。

### `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`

- **值**：设为 `1` 启用
- **作用**：移除 Anthropic 特有的 `anthropic-beta` 请求头和 beta 工具 schema 字段（如 `defer_loading`、`eager_input_streaming`）。标准字段（`name`、`description`、`input_schema`、`cache_control`）不受影响
- **触发场景**：
  - `Unexpected value(s) for the 'anthropic-beta' header`
  - `Extra inputs are not permitted`
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
```

### `CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK`

- **值**：设为 `1` 启用
- **作用**：禁用流式请求失败后的非流式回退。流式错误将直接传播到重试层
- **触发场景**：网关导致非流式回退产生重复工具执行
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK": "1"
  }
}
```

### `CLAUDE_CODE_ATTRIBUTION_HEADER`

- **值**：设为 `0` 禁用归属信息
- **作用**：移除系统提示开头的归属块（客户端版本和提示指纹）。禁用后可提升网关环境下的 prompt-cache 命中率。Anthropic 直连 API 的缓存不受影响
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
```

### `API_TIMEOUT_MS`

- **值**：毫秒数（默认 600000，即 10 分钟；最大 2147483647）
- **作用**：设置 API 请求超时时间。慢网络或代理环境下需要增大此值。超过最大值会导致计时器溢出，请求立即失败
- **配置方式**：

```json
{
  "env": {
    "API_TIMEOUT_MS": "1200000"
  }
}
```

---

## 功能增强

可选配置，用于在网关环境下启用额外功能。

### `ENABLE_TOOL_SEARCH`

- **值**：设为 `true` 启用
- **作用**：当 `ANTHROPIC_BASE_URL` 指向第三方网关时，MCP 工具搜索默认禁用。设为 `true` 可重新启用，但前提是网关支持转发 `tool_reference` 块
- **默认状态**：网关环境下关闭
- **配置方式**：

```json
{
  "env": {
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

### `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY`

- **值**：设为 `1` 启用
- **作用**：从网关的 `/v1/models` 端点自动发现可用模型，填充 `/model` 选择器。适用于 LiteLLM、Kong 等兼容 Anthropic 的网关。默认关闭，因为共享 API Key 的网关会暴露所有可用模型。发现的模型仍受 `availableModels` 白名单过滤
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1"
  }
}
```

### `CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING`

- **值**：设为 `0` 禁用，设为 `1` 强制启用
- **作用**：控制工具调用输入是否在生成过程中流式传输。关闭时，大型工具输入（如长文件写入）需等 Claude 完全生成后才一次性返回，看起来像卡住；开启后可实时看到参数逐步生成
- **默认状态**：
  - Anthropic 直连 API：开启
  - Bedrock / Vertex：按模型自动判断
  - Foundry / 网关连接：**关闭**
- **前提**：网关需支持流式传输工具调用输入
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING": "1"
  }
}
```

### `CLAUDE_CODE_MAX_CONTEXT_TOKENS`

- **值**：token 数量
- **作用**：覆盖 Claude Code 假设的上下文窗口大小。仅在同时设置 `DISABLE_COMPACT` 时生效。当网关后端模型的上下文窗口与内置值不匹配时使用
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_MAX_CONTEXT_TOKENS": "200000",
    "DISABLE_COMPACT": "1"
  }
}
```

### `CLAUDE_CODE_PROXY_RESOLVES_HOSTS`

- **值**：设为 `1` 启用
- **作用**：允许代理执行 DNS 解析而非由调用方解析。适用于代理需要处理主机名解析的环境
- **配置方式**：

```json
{
  "env": {
    "CLAUDE_CODE_PROXY_RESOLVES_HOSTS": "1"
  }
}
```

### `ANTHROPIC_CUSTOM_MODEL_OPTION`

- **值**：模型 ID
- **作用**：在 `/model` 选择器中添加自定义模型条目。用于将非标准或网关特定的模型设为可选，而不替换内置别名
- **配置方式**：

```json
{
  "env": {
    "ANTHROPIC_CUSTOM_MODEL_OPTION": "your-custom-model-id"
  }
}
```

### `ANTHROPIC_CUSTOM_HEADERS`

- **值**：`Name: Value` 格式，多个用换行分隔
- **作用**：向请求添加自定义头。用于需要额外头信息的网关
- **配置方式**：

```json
{
  "env": {
    "ANTHROPIC_CUSTOM_HEADERS": "X-Custom-Header: value1\nX-Another-Header: value2"
  }
}
```

---

## 平台特定配置

### AWS Bedrock

| 变量 | 说明 |
|------|------|
| `CLAUDE_CODE_USE_BEDROCK` | 设为 `1` 启用 Bedrock 模式 |
| `ANTHROPIC_BEDROCK_BASE_URL` | 覆盖 Bedrock 端点 URL，用于自定义 Bedrock 端点或通过 LLM 网关路由 |
| `ANTHROPIC_BEDROCK_SERVICE_TIER` | Bedrock 服务层级（`default`、`flex`、`priority`），作为 `X-Amzn-Bedrock-Service-Tier` 头发送 |
| `ANTHROPIC_BEDROCK_MANTLE_BASE_URL` | 覆盖 Bedrock Mantle 端点 URL |
| `AWS_BEARER_TOKEN_BEDROCK` | Bedrock API Key 认证 |
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | 跳过 AWS 认证（使用 LLM 网关时） |
| `ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION` | 覆盖 Haiku 模型的 AWS 区域 |

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
    "ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION": "us-east-1"
  }
}
```

### Google Vertex AI

| 变量 | 说明 |
|------|------|
| `CLAUDE_CODE_USE_VERTEX` | 设为 `1` 启用 Vertex 模式 |
| `ANTHROPIC_VERTEX_BASE_URL` | 覆盖 Vertex AI 端点 URL，用于自定义端点或通过 LLM 网关路由 |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP 项目 ID，会被 `GCLOUD_PROJECT`、`GOOGLE_CLOUD_PROJECT` 或 `GOOGLE_APPLICATION_CREDENTIALS` 中的项目覆盖 |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH` | 跳过 Google 认证（使用 LLM 网关时） |

```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
    "ANTHROPIC_VERTEX_PROJECT_ID": "your-gcp-project-id"
  }
}
```

### Microsoft Foundry (Azure AI)

| 变量 | 说明 |
|------|------|
| `CLAUDE_CODE_USE_FOUNDRY` | 设为 `1` 启用 Foundry 模式 |
| `ANTHROPIC_FOUNDRY_BASE_URL` | Foundry 资源的完整基础 URL（如 `https://my-resource.services.ai.azure.com/anthropic`） |
| `ANTHROPIC_FOUNDRY_RESOURCE` | Foundry 资源名称（如 `my-resource`），未设置 `ANTHROPIC_FOUNDRY_BASE_URL` 时必填 |
| `ANTHROPIC_FOUNDRY_API_KEY` | Foundry API Key |
| `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` | 跳过 Azure 认证（使用 LLM 网关时） |

```json
{
  "env": {
    "CLAUDE_CODE_USE_FOUNDRY": "1",
    "ANTHROPIC_FOUNDRY_BASE_URL": "https://my-resource.services.ai.azure.com/anthropic",
    "ANTHROPIC_FOUNDRY_API_KEY": "your-foundry-key",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
```

---

## 通用配置示例

### 最简配置（LiteLLM / Kong / 自建网关）

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "your-gateway-key",
    "ANTHROPIC_BASE_URL": "https://your-gateway.example.com/v1"
  }
}
```

### 完整兼容配置

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "your-gateway-key",
    "ANTHROPIC_BASE_URL": "https://your-gateway.example.com/v1",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
    "CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK": "1",
    "CLAUDE_CODE_ATTRIBUTION_HEADER": "0"
  }
}
```

### 全功能网关配置

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "your-gateway-key",
    "ANTHROPIC_BASE_URL": "https://your-gateway.example.com/v1",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
    "CLAUDE_CODE_ENABLE_FINE_GRAINED_TOOL_STREAMING": "1",
    "ENABLE_TOOL_SEARCH": "true"
  }
}
```

---

## 配置原则

**先最小配置，按需添加。** 只配 `ANTHROPIC_BASE_URL` + `ANTHROPIC_API_KEY`，遇到具体报错再加对应的兼容性变量。不需要提前把所有变量都设上。

---

*文档生成日期：2026-05-21*
*数据来源：Claude Code 官方文档 code.claude.com/docs/en/env-vars*
