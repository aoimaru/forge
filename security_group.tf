# --- アプリケーション(認証)サーバ用のセキュリティグループ ------------------------------------
# ALB→アプリ 8080からの通信を許可
# アプリ→RDS 5432への通信を許可
# 踏み台サーバ→アプリ 8080への通信を許可
resource "aws_security_group" "app_sg" {
  name        = "${var.project}-${var.environment}-${var.ver}-app-sg"
  description = "application server role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-${var.ver}-app-sg"
    Project = var.project
    Env     = var.environment
    Ver     = var.ver
  }
}
# 踏み台サーバ→アプリ
resource "aws_security_group_rule" "app_rule_opmng_to_app" {
  security_group_id        = aws_security_group.app_sg.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  source_security_group_id = aws_security_group.opmng_sg.id
}
# SSM用のポートを開けるルールを追加
resource "aws_security_group_rule" "app_rule_from_ssm_to_app" {
  security_group_id = aws_security_group.app_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
# -------------------------------------------------------------------------

# --- 踏み台サーバ: opmng security group ------------------------------------
resource "aws_security_group" "opmng_sg" {
  name        = "${var.project}-${var.environment}-${var.ver}-opmng-sg"
  description = "operation and management role security group"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name    = "${var.project}-${var.environment}-${var.ver}-opmng-sg"
    Project = var.project
    Env     = var.environment
    Ver     = var.ver
  }

}
# SSM接続用のルールを追加
# 踏み台サーバから外への443の通信は許可する(SSMエンドポイント用)
resource "aws_security_group_rule" "opmng_rule_to_https" {
  security_group_id = aws_security_group.opmng_sg.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}
# 踏み台サーバからRDSへの接続を許可するルールを追加
resource "aws_security_group_rule" "opmng_out_to_rds" {
  security_group_id        = aws_security_group.opmng_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  # source_security_group_id = aws_security_group.db_sg.id
  cidr_blocks = ["0.0.0.0/0"]
}
# アプリケーションサーバ→踏み台サーバの通信も許可するルールを追加
resource "aws_security_group_rule" "opmng_rule_opmng_to_app" {
  security_group_id        = aws_security_group.opmng_sg.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  # source_security_group_id = aws_security_group.app_sg.id
  cidr_blocks = ["0.0.0.0/0"]
}
# -------------------------------------------------------------------------

# --- SSMエンドポイント用のセキュリティグループ ------------------------------------
resource "aws_security_group" "ssm_endpoint_sg" {
  name        = "${var.project}-${var.environment}-${var.ver}-ssm-endpoint-sg"
  description = "ssm vpc endpoint security group"
  vpc_id      = aws_vpc.vpc.id

  # VPCエンドポイントへの通信
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Allow EC2 HTTPS"
    # 踏み台サーバのセキュリティグループからの通信を許可
    security_groups = [aws_security_group.opmng_sg.id, aws_security_group.app_sg.id]
  }

  # VPCエンドポイントから外への通信
  # プライベートサブネット内への通信となる
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # 参考: https://techblog.nhn-techorus.com/archives/32527

  tags = {
    Name    = "${var.project}-${var.environment}-${var.ver}-ssm-endpoint-sg"
    Project = var.project
    Env     = var.environment
    Ver     = var.ver
  }
}
# ----------------------------------------------------------------------------
