// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:opendoors/model/fontfamily_model.dart';
import 'package:opendoors/utils/Colors.dart';
import 'package:opendoors/utils/Dark_lightmode.dart';

class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({
    super.key,
    required this.notifire,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.loadingProvider,
  });

  final ColorNotifire notifire;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final String? loadingProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: notifire.getborderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "OR".tr,
                  style: TextStyle(
                    fontFamily: FontFamily.gilroyMedium,
                    color: notifire.getgreycolor,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: notifire.getborderColor)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SocialAuthButton(
                  label: "Google".tr,
                  asset: "assets/svg/google_logo.svg",
                  notifire: notifire,
                  isLoading: loadingProvider == "google",
                  onTap: loadingProvider == null ? onGoogleTap : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SocialAuthButton(
                  label: "Apple".tr,
                  asset: "assets/svg/apple_logo.svg",
                  notifire: notifire,
                  isLoading: loadingProvider == "apple",
                  onTap: loadingProvider == null ? onAppleTap : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.asset,
    required this.notifire,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final String asset;
  final ColorNotifire notifire;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: notifire.getboxcolor,
          border: Border.all(color: notifire.getborderColor),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0.5, 0.5),
              blurRadius: 1,
            ),
          ],
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(blueColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    asset,
                    height: 20,
                    width: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: notifire.getwhiteblackcolor,
                        fontFamily: FontFamily.gilroyBold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
