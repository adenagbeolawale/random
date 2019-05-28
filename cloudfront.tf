#very basic cloudfront distribution configuration
resource "aws_cloudfront_distribution" "wordpress_distribution" {
  comment          = "wordpress distribution"
  price_class      = "${var.CLOUDFRONT_PRICE_CLASS}"
  aliases          = "${var.CLOUDFRONT_ALIASES}"
  retain_on_delete = false
  enabled          = true

  origin {
    domain_name = "${aws_elb.wordpress_elb.dns_name}"
    origin_id   = "ELB-${aws_elb.wordpress_elb.name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2", "SSLv3"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ELB-${aws_elb.wordpress_elb.name}"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}