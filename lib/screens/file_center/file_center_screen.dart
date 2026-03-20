import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../home/groups_screen.dart';
import 'file_upload_screen.dart';

class FileCenterScreen extends StatefulWidget {
  const FileCenterScreen({super.key});

  @override
  State<FileCenterScreen> createState() => _FileCenterScreenState();
}

class _FileCenterScreenState extends State<FileCenterScreen> {
  final _qCtrl = TextEditingController();
  Timer? _debounce;

  List<dynamic> _files = [];
  bool _loading = true;

  int? _groupId;
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final params = <String, String>{'limit': '60'};
    final q = _qCtrl.text.trim();
    if (q.isNotEmpty) params['q'] = q;
    if (_groupId != null) params['group_id'] = '$_groupId';
    if (_category != 'all') params['category'] = _category;

    final r = await ApiService.get(ApiConfig.files, params: params);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true) {
        _files = r['data']?['files'] as List? ?? [];
      }
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _pickGroup() async {
    final res = await ApiService.get(ApiConfig.groups, params: {'filter': 'mine'});
    final groups = (res['success'] == true) ? (res['data']?['groups'] as List? ?? []) : <dynamic>[];
    if (!mounted) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GroupPickerSheet(groups: groups),
    );

    if (!mounted) return;
    setState(() {
      _groupId = selected?['group_id'] as int?;
    });
    _load();
  }

  Future<void> _deleteFile(int fileId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الملف؟'),
        content: const Text('سيتم حذف الملف نهائيًا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await ApiService.delete('${ApiConfig.files}?id=$fileId');
    _load();
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رابط التحميل')));
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل فتح رابط التحميل')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز الملفات'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const FileUploadScreen()));
          if (mounted) _load();
        },
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('رفع ملف'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _qCtrl,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن ملف...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickGroup,
                        icon: const Icon(Icons.groups_outlined),
                        label: Text(_groupId == null ? 'كل المجموعات' : 'تصفية بالمجموعة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('كل الأنواع')),
                          DropdownMenuItem(value: 'lecture', child: Text('محاضرات')),
                          DropdownMenuItem(value: 'assignment', child: Text('واجبات')),
                          DropdownMenuItem(value: 'reference', child: Text('مراجع')),
                          DropdownMenuItem(value: 'other', child: Text('أخرى')),
                        ],
                        onChanged: (v) {
                          setState(() => _category = v ?? 'all');
                          _load();
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('لا توجد ملفات', style: TextStyle(color: Colors.grey)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: _files.length,
                          itemBuilder: (_, i) {
                            final f = _files[i] as Map<String, dynamic>;
                            final name = (f['title'] as String?)?.trim().isNotEmpty == true
                                ? (f['title'] as String)
                                : (f['original_name'] as String? ?? 'ملف');
                            final type = f['file_type'] ?? 'other';
                            final icon = {
                              'pdf': Icons.picture_as_pdf_outlined,
                              'image': Icons.image_outlined,
                              'presentation': Icons.slideshow_outlined,
                              'archive': Icons.archive_outlined,
                              'video': Icons.movie_outlined,
                              'other': Icons.insert_drive_file_outlined,
                            }[type] ?? Icons.insert_drive_file_outlined;
                            final url = (f['download_url'] as String?) ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: Icon(icon, color: const Color(0xFF2563EB)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                subtitle: Text(
                                  [
                                    if ((f['uploader_name'] ?? '').toString().isNotEmpty) 'رفع بواسطة: ${f['uploader_name']}',
                                    if ((f['group_name'] ?? '').toString().isNotEmpty) 'المجموعة: ${f['group_name']}',
                                  ].join(' • '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'download' && url.isNotEmpty) _downloadFile(url);
                                    if (v == 'copy' && url.isNotEmpty) _copyUrl(url);
                                    if (v == 'delete') _deleteFile((f['file_id'] as int));
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'download', child: Text('تنزيل الملف')),
                                    const PopupMenuItem(value: 'copy', child: Text('نسخ الرابط')),
                                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                                  ],
                                ),
                                onTap: url.isEmpty
                                    ? null
                                    : () => _downloadFile(url),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GroupPickerSheet extends StatelessWidget {
  final List<dynamic> groups;
  const _GroupPickerSheet({required this.groups});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('بدون تصفية'),
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 0),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد مجموعات لعرضها', style: TextStyle(color: Colors.grey)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: groups.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) {
                  final g = groups[i] as Map<String, dynamic>;
                  return ListTile(
                    leading: const CircleAvatar(child: Text('👥')),
                    title: Text(g['group_name'] ?? ''),
                    onTap: () => Navigator.pop(context, g),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

