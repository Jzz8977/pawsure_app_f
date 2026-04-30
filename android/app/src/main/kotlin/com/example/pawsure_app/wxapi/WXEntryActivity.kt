package com.example.pawsure_app.wxapi

import com.jarvan.fluwx.wxapi.FluwxWXEntryActivity

/**
 * 微信开放平台要求：当前应用 applicationId 下必须存在 `wxapi.WXEntryActivity`，
 * 否则 fluwx 的回调（授权 code、分享结果等）拿不到。
 *
 * fluwx 提供了基类 [FluwxWXEntryActivity]，这里继承一个空类即可，
 * 所有逻辑由父类完成 → 转发给 Dart 层订阅者。
 */
class WXEntryActivity : FluwxWXEntryActivity()
