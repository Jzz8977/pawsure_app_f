import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_nav_bar.dart';

class PlatformRulesPage extends StatelessWidget {
  const PlatformRulesPage({super.key});

  static const _sections = [
    ('一、平台规则总览', '宠信平台作为专业的宠物服务撮合平台，制定本规则旨在保障平台上服务提供者与宠物主人的合法权益，维护平台良好的交易秩序。所有用户在使用本平台服务时，均须遵守本规则。'),
    ('二、服务提供者准入规则', '2.1 服务提供者须完成实名认证，提交真实有效的身份证明材料。\n2.2 服务提供者须具备相应的宠物照料知识和经验，通过平台审核。\n2.3 服务提供者须缴纳保证金，金额根据服务类型确定。\n2.4 服务提供者须保持个人信息更新，如有变更须及时修改。'),
    ('三、服务标准规范', '3.1 服务提供者须按照预约时间准时提供服务，如有特殊情况须提前告知用户。\n3.2 服务期间须按时打卡记录，保障用户宠物安全。\n3.3 服务过程中须爱护用户宠物，禁止任何形式的虐待行为。\n3.4 服务期间如发现宠物健康异常，须立即通知宠物主人并采取相应措施。'),
    ('四、定价与支付规则', '4.1 服务价格由服务提供者自行设定，但须在平台规定的合理范围内。\n4.2 用户支付的服务费用由平台代为保管，服务完成后结算给服务提供者。\n4.3 平台对每笔交易收取一定比例的服务费用，具体比例以平台公告为准。\n4.4 服务提供者的收入可随时申请提现，提现处理时间为1-3个工作日。'),
    ('五、评价与信用规则', '5.1 每次服务完成后，用户可对服务提供者进行评价打分。\n5.2 评价内容须真实客观，不得恶意差评或虚假好评。\n5.3 平台根据综合评分对服务提供者进行排序，高评分服务提供者将获得更多曝光。\n5.4 累计差评达到一定数量的服务提供者将被限制接单或下架处理。'),
    ('六、纠纷处理规则', '6.1 服务过程中发生纠纷，双方应首先友好协商解决。\n6.2 协商不成的，任一方可申请平台介入调解。\n6.3 平台将根据双方提供的证据和实际情况，公正裁决纠纷。\n6.4 如宠物在服务期间受到伤害，平台将协助用户通过保险途径获得赔偿。'),
    ('七、违规处理规则', '7.1 对于违反平台规则的用户，平台将根据情节轻重采取警告、限流、封号等处理措施。\n7.2 服务提供者存在欺诈、虐待宠物等严重违规行为的，将被永久封号并没收保证金。\n7.3 被处理的用户可在规定时间内提出申诉，平台将重新审核处理决定。'),
    ('八、规则更新说明', '本规则由平台定期更新，更新内容将通过平台公告形式通知用户。用户继续使用平台服务即视为接受更新后的规则。如对规则有任何疑问，可联系平台客服获得解答。'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '平台规则'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Container(
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
                '平台规则',
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
      ),
    );
  }
}
