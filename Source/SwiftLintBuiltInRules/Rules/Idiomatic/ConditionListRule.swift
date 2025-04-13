import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ConditionListRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "condition_list",
        name: "Condition List",
        description: "Prefer condition lists over boolean expressions with &&.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("if a, b {}"),
            Example("while a || b, c {}"),
            Example("do {} while a || b && c"),
            Example("if a, { b && c }}() {}"),
            Example("guard a, b else { return }"),
        ],
        triggeringExamples: [
            Example("if ↓a && ↓b {}"),
            Example("while ↓(a || b) && ↓c {}"),
            Example("guard ↓a && ↓b else { return }"),
        ]
    )
}

private extension ConditionListRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            checkCondition(node.conditions)
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            checkCondition(node.conditions)
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            checkCondition(node.conditions)
        }

        private func checkCondition(_ conditions: ConditionElementListSyntax) {
            guard conditions.count == 1,
                  let firstCondition = conditions.first,
                  case .expression(let expr) = firstCondition.condition else {
                return
            }

            findLogicalAndExpressions(in: expr)
        }

        private func findLogicalAndExpressions(in expr: ExprSyntax) {
            if let binaryExpr = expr.as(InfixOperatorExprSyntax.self),
               let op = binaryExpr.operator.as(BinaryOperatorExprSyntax.self),
               op.operator.text == "&&" {
                violations.append(binaryExpr.operator.positionAfterSkippingLeadingTrivia)
                findLogicalAndExpressions(in: binaryExpr.leftOperand)
                findLogicalAndExpressions(in: binaryExpr.rightOperand)
            }
        }
    }
}
