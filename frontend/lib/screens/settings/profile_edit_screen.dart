/// =============================================================
/// File : profile_edit_screen.dart
/// Desc : 프로필 수정
/// Auth : yunha Hwang (DKU)
/// Crtd : 2025-04-21
/// Updt : 2025-06-01
/// =============================================================
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:scholarai/constants/app_colors.dart';
import 'package:scholarai/constants/config.dart';
import 'package:scholarai/providers/auth_provider.dart';
import 'package:scholarai/providers/user_profile_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController nameController = TextEditingController();

  int? selectedYear;
  String? selectedGender;
  String? selectedRegion;
  String? selectedUniversityType;
  String? selectedAcademicStatus;
  String? selectedUniversity;
  String? selectedMajorField;
  String? selectedMajor;
  int? selectedSemester;
  int? selectedIncomeLevel;
  double selectedGpa = 0.0;
  bool isDisabled = false;
  bool isMultiChild = false;
  bool isBasicLiving = false;
  bool isSecondLowest = false;
  String errorMessage = '';
  int? profileId;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.memberId;
      final token = authProvider.token;

      if (userId == null) {
        setState(() {
          errorMessage = '로그인된 사용자 정보가 없습니다';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);
        profileId = profileData['profileId'];
        selectedYear = profileData['birthYear'];
        selectedGender = profileData['gender'];
        selectedRegion = profileData['residence'];
        selectedUniversityType = profileData['universityType'];
        selectedAcademicStatus = profileData['academicStatus'];
        selectedMajorField = profileData['majorField'];
        selectedMajor = profileData['major'];
        selectedUniversity = profileData['university'];
        selectedGpa = profileData['gpa']?.toDouble() ?? 0.0;
        selectedSemester = profileData['semester'];
        selectedIncomeLevel = profileData['incomeLevel'];
        isDisabled = profileData['disabled'] ?? false;
        isMultiChild = profileData['multiChild'] ?? false;
        isBasicLiving = profileData['basicLivingRecipient'] ?? false;
        isSecondLowest = profileData['secondLowestIncome'] ?? false;
        setState(() {});
      } else {
        setState(() {
          errorMessage = '프로필 불러오기에 실패했습니다';
        });
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      setState(() {
        errorMessage = '네트워크 오류: 연결을 확인해주세요';
      });
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final isEmptyProfile = profileProvider.isProfileEmpty;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final memberId = authProvider.memberId;
      final token = authProvider.token;

      if (memberId == null) {
        setState(() {
          errorMessage = '로그인된 사용자 정보가 없습니다';
        });
        return;
      }

      final Map<String, dynamic> body = {
        'birthYear': selectedYear,
        'gender': selectedGender,
        'residence': selectedRegion,
        'universityType': selectedUniversityType,
        'university': selectedUniversity,
        'academicStatus': selectedAcademicStatus,
        'semester': selectedSemester,
        'majorField': selectedMajorField,
        'major': selectedMajor,
        'gpa': selectedGpa,
        'incomeLevel': selectedIncomeLevel,
        'disabled': isDisabled,
        'multiChild': isMultiChild,
        'basicLivingRecipient': isBasicLiving,
        'secondLowestIncome': isSecondLowest,
      };

      print('📡 전송할 프로필 정보: $body');

      http.Response response;
      if (isEmptyProfile) {
        final url = Uri.parse('$baseUrl/api/profile?memberId=$memberId');
        print('🛰️ POST URL: $url');
        print('🔐 Bearer Token: $token');

        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      } else {
        final url = Uri.parse('$baseUrl/api/profile/$profileId');
        response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      }

      print('📩 응답코드: ${response.statusCode}');
      print('📩 응답내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        profileProvider.updateProfile(
          birthYear: selectedYear,
          gender: selectedGender,
          region: selectedRegion,
          university: selectedUniversity,
          universityType: selectedUniversityType,
          academicStatus: selectedAcademicStatus,
          majorField: selectedMajorField,
          major: selectedMajor,
          gpa: selectedGpa,
          semester: selectedSemester,
          incomeLevel: selectedIncomeLevel,
          disabled: isDisabled,
          multiChild: isMultiChild,
          basicLivingRecipient: isBasicLiving,
          secondLowestIncome: isSecondLowest,
        );
        context.pop();
      } else {
        setState(() {
          errorMessage = '프로필 저장에 실패했습니다';
        });
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      setState(() {
        errorMessage = '네트워크 오류: 연결을 확인해주세요';
      });
    }
  }


  final List<int> yearOptions = List.generate(
    60,
    (i) => DateTime.now().year - i,
  );
  final List<Map<String, String>> genderOptions = [
    {'value': 'MALE', 'label': '남자'},
    {'value': 'FEMALE', 'label': '여자'},
  ];

  final List<String> regionOptions = [
    '서울특별시',
    '부산광역시',
    '대구광역시',
    '인천광역시',
    '광주광역시',
    '대전광역시',
    '울산광역시',
    '세종특별자치시',
    '경기도',
    '강원도',
    '충청북도',
    '충청남도',
    '전라북도',
    '전라남도',
    '경상북도',
    '경상남도',
    '제주특별자치도',
  ];
  final List<String> universityTypes = ['4년제', '전문대', '기타'];
  final List<Map<String, String>> academicStatuses = [
    {'code': 'ENROLLED', 'label': '재학'},
    {'code': 'LEAVE_OF_ABSENCE', 'label': '휴학'},
    {'code': 'EXPECTED_GRADUATION', 'label': '졸업예정'},
    {'code': 'GRADUATED', 'label': '졸업'},
  ];
  final List<String> majorFields = [
    '공학계열',
    '자연계열',
    '인문계열',
    '사회계열',
    '예체능계열',
    '의약계열',
    '교육계열',
    '기타',
  ];
  final List<int> semesterOptions = List.generate(12, (i) => i + 1);
  final List<int> incomeLevels = List.generate(9, (i) => i + 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Column(children: [const SizedBox(height: 24)])),
            _buildDropdownRow(
              '출생년도',
              selectedYear,
              yearOptions,
              (val) => setState(() => selectedYear = val),
              isInt: true,
            ),
            _buildDropdownRow(
              '성별',
              selectedGender,
              genderOptions,
              (val) => setState(() => selectedGender = val),
              isMap: true,
            ),
            _buildDropdownRow(
              '소득 분위',
              selectedIncomeLevel,
              incomeLevels,
              (val) => setState(() => selectedIncomeLevel = val),
              isInt: true,
            ),
            _buildDropdownRow(
              '거주지',
              selectedRegion,
              regionOptions,
              (val) => setState(() => selectedRegion = val),
            ),
            _buildDropdownRow(
              '대학구분',
              selectedUniversityType,
              universityTypes,
              (val) => setState(() => selectedUniversityType = val),
            ),
            _buildDropdownRow(
              '학적 상태',
              selectedAcademicStatus,
              academicStatuses,
              (val) => setState(() => selectedAcademicStatus = val),
              isMap: true,
            ),
            _buildDropdownRow(
              '학기',
              selectedSemester,
              semesterOptions,
              (val) => setState(() => selectedSemester = val),
              isInt: true,
            ),
            _buildDropdownRow(
              '학과 구분',
              selectedMajorField,
              majorFields,
              (val) => setState(() => selectedMajorField = val),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: const Text(
                    '대학명',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: (value) => selectedUniversity = value,
                    decoration: const InputDecoration(
                      hintText: '입력 안 함',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: const Text(
                    '전공명',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    onChanged: (value) => selectedMajor = value,
                    decoration: const InputDecoration(
                      hintText: '입력 안 함',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: const Text(
                    '성적',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${selectedGpa.toStringAsFixed(2)} / 4.50',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      Slider(
                        value: selectedGpa,
                        min: 0.0,
                        max: 4.5,
                        divisions: 90,
                        label: selectedGpa.toStringAsFixed(2),
                        onChanged:
                            (value) => setState(() => selectedGpa = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('장애 여부'),
                    value: isDisabled,
                    onChanged:
                        (value) => setState(() => isDisabled = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('다자녀 가구 여부'),
                    value: isMultiChild,
                    onChanged:
                        (value) =>
                            setState(() => isMultiChild = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('기초생활수급자 여부'),
                    value: isBasicLiving,
                    onChanged:
                        (value) =>
                            setState(() => isBasicLiving = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('차상위계층 여부'),
                    value: isSecondLowest,
                    onChanged:
                        (value) =>
                            setState(() => isSecondLowest = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _saveProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(
    String title,
    dynamic selectedValue,
    List options,
    Function(dynamic) onChanged, {
    bool isInt = false,
    bool isMap = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField(
              value: selectedValue,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('선택 안 함')),
                ...options.map((option) {
                  if (isMap) {
                    return DropdownMenuItem(
                      value: option['value'] ?? option['code'],
                      child: Text(option['label']!),
                    );
                  } else {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(isInt ? '$option' : option.toString()),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String title, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
