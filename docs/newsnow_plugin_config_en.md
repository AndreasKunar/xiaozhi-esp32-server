# get_news_from_newsnow Plugin News Source Configuration Guide

## Overview

The `get_news_from_newsnow` plugin now supports dynamic configuration of news sources through the web management interface, eliminating the need to modify code. Users can configure different news sources for each Smart Agent in the Smart Console.

## Configuration Methods

### 1. Configure via Web Management Interface (Recommended)

1. Log in to the Smart Console.  
2. Navigate to the **"Role Configuration"** page.  
3. Select the Smart Agent you wish to configure.  
4. Click the **"Edit Function"** button.  
5. In the parameter configuration area on the right, locate the **"newsnow news aggregation"** plugin.  
6. In the **"News Source Configuration"** field, enter a semicolon‑separated list of Chinese names.

### 2. Configure via Configuration File

In `config.yaml` configure as follows:

```yaml
plugins:
  get_news_from_newsnow:
    url: "https://newsnow.busiyi.world/api/s?id="
    news_sources: "澎湃新闻;百度热搜;财联社;微博;抖音"
```

## News Source Configuration Format

News source configuration uses Chinese names separated by semicolons, formatted as:

```
Chinese Name 1;Chinese Name 2;Chinese Name 3
```

### Configuration Example

```
ThePaper;Baidu Hot Search;Cailian She;Weibo;Douyin;Zhihu;36Kr
```

## Supported News Sources

The plugin supports the following Chinese names for news sources:

- ThePaper  
- Baidu Hot Search  
- Cailian She (FinancialWire)  
- Weibo  
- Douyin  
- Zhihu  
- 36Kr  
- Wall Street Journal (in Chinese context)  
- IT Home  
- Today's Headlines (TikTok News)  
- Tieba (Baidu Tieba)  
- Huobi Forum (Kufu Forum)  
- Bilibili  
- Kuaishou  
- Snowball  
- Guokr (Less Popular)  
- JuFin (Fabric Finance)  
- Golden Data (JinShu Data)  
- Cowboy (Niuke)  
- Minority (ShaoShang)  
- Ruidao (Mineral)  
- Phoenix Network  
- Insect Tribe (ChongBuLuo)  
- United Daily News (LianHe Zaobao)  
- CoolGame (KuAn)  
- Future Forum (YuanJing LunTan)  
- Reference News (CaoZhou XinWen)  
- Satellite News Agency (WeiXing TongXunShe)  
- Baidu Tieba  
- Reliable News (KaoPu XinWen)  
- and more...

## Default Configuration

If no news sources are configured, the plugin will use the following default configuration:

```
ThePaper;Baidu Hot Search;Cailian She
```

## Usage Instructions

1. **Configure news sources**: Set the Chinese names of news sources in the web interface or configuration file, separated by semicolons.  
2. **Invoke the plugin**: Users can say "Play news" or "Get news".  
3. **Specify a news source**: Users can say "Play ThePaper" or "Get Baidu Hot Search".  
4. **Get details**: Users can ask "Give a detailed introduction of this news".

## Working Principle

1. The plugin accepts a Chinese name as a parameter (e.g., "ThePaper").  
2. It maps the Chinese name to the corresponding English ID defined in `CHANNEL_MAP` (e.g., "thepaper").  
3. It calls the API using the English ID to retrieve news data.  
4. The retrieved news content is returned to the user.

## Important Notes

1. The configured Chinese names must exactly match the names defined in `CHANNEL_MAP`.  
2. After configuration changes, you need to restart the service or reload the configuration.  
3. If an invalid news source is configured, the plugin will automatically fall back to the default news sources.  
4. Use English semicolons (`;`) to separate multiple news sources; do **not** use Chinese semicolons (``).
