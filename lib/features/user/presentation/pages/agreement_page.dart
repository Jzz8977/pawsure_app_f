import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_nav_bar.dart';

class AgreementPage extends StatelessWidget {
  const AgreementPage({super.key});

  static const _sections = [
    ('一、总则', '1.1 本协议是您（以下称"用户"）与宠信平台（以下称"平台"）之间关于使用宠信服务的法律协议。\n1.2 您在使用本平台服务前，应仔细阅读本协议。一旦您开始使用本平台服务，即视为您已充分理解并接受本协议的全部内容。\n1.3 本平台有权根据需要不时修订本协议，修订后的协议一经发布即生效。'),
    ('二、账号注册与安全', '2.1 您在注册账号时，必须提供真实、准确、完整的个人信息，并及时更新以保证信息的准确性。\n2.2 您应对账号及密码的安全负全部责任，不得将账号、密码转让或出借给他人使用。\n2.3 如发现账号遭到未经授权使用，请立即通知本平台。'),
    ('三、服务内容', '3.1 本平台提供宠物寄养、宠物护理、宠物保险等相关服务的信息撮合平台。\n3.2 本平台仅提供服务信息发布和交易撮合服务，不直接提供宠物护理服务。\n3.3 平台有权根据实际情况调整服务内容，并以公告形式通知用户。'),
    ('四、用户行为规范', '4.1 用户在使用本平台服务时，必须遵守中华人民共和国相关法律法规。\n4.2 用户不得利用本平台从事任何违法违规活动，包括但不限于发布虚假信息、侵犯他人权益等。\n4.3 用户不得干扰、破坏本平台的正常运营。'),
    ('五、交易规则', '5.1 用户在平台上进行的交易，应遵守平台发布的交易规则。\n5.2 交易双方应诚实守信，履行各自的交易义务。\n5.3 如产生交易纠纷，双方应友好协商解决；协商不成的，可申请平台介入调解。'),
    ('六、隐私保护', '6.1 本平台重视用户隐私保护，将依照《隐私政策》收集、使用和保护您的个人信息。\n6.2 未经您的同意，本平台不会向任何第三方泄露您的个人信息，法律法规要求的除外。\n6.3 本平台采用行业标准的安全措施保护您的个人信息。'),
    ('七、知识产权', '7.1 本平台上所有内容，包括但不限于文字、图片、软件、声音、设计等，均受知识产权法律法规的保护。\n7.2 未经本平台明确许可，用户不得复制、转载、修改或以其他方式使用平台上的内容。'),
    ('八、免责声明', '8.1 本平台对服务提供者的资质进行必要审核，但不对其服务质量提供担保。\n8.2 因不可抗力或平台合理控制范围之外的原因导致服务中断，本平台不承担责任。\n8.3 用户因违反本协议或相关法律法规而产生的任何后果，由用户自行承担。'),
    ('九、协议终止', '9.1 用户可随时申请注销账号，终止本协议。\n9.2 如用户违反本协议，本平台有权暂停或终止向用户提供服务，并有权删除用户账号及相关信息。\n9.3 本协议终止后，本平台无义务向用户保留任何账号信息。'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '用户协议'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '用户服务协议',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '最后更新：2025年1月1日',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '欢迎使用宠信平台服务，在使用前请仔细阅读以下协议内容。',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  for (final section in _sections) ...[
                    Text(
                      section.$1,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.$2,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.7),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
