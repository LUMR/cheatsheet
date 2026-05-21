# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个纯文档仓库，包含常用开发工具与命令的中文速查表。没有源代码、构建系统或测试。内容通过 GitHub Markdown 渲染。

## 仓库结构

根目录下每个 `.md` 文件是一个独立主题的速查表（Git、Docker、Linux、npm、正则等），统一使用 Markdown 表格格式（`命令 | 说明`）。`README.md` 是目录索引。

`claude-code/` 子目录存放 Claude Code 配置示例和脚本，不属于速查表内容。

## 编辑规范

- 语言：中文描述 + 英文命令语法
- 格式：使用 Markdown 管道表格，列为"命令"和"说明"
- 每个文件聚焦一个工具/主题，保持简洁实用
- 新增速查表后需在 `README.md` 的目录中添加链接
