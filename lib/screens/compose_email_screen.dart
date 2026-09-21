import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../main.dart';

class ComposeEmailScreen extends StatefulWidget {
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;

  const ComposeEmailScreen({
    super.key,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
  });

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTo != null) _toController.text = widget.initialTo!;
    if (widget.initialSubject != null)
      _subjectController.text = widget.initialSubject!;
    if (widget.initialBody != null) _bodyController.text = widget.initialBody!;
  }

  bool isSending = false;
  bool isPreviewMode = false;
  List<PlatformFile> attachedFiles = [];

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              selection.start +
              prefix.length +
              selectedText.length +
              suffix.length,
        ),
      );
    } else {
      final newText = text + prefix + suffix;
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - suffix.length,
        ),
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty) {
      setState(() {
        attachedFiles.addAll(result);
      });
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSending = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://strong-jeans-shave.loca.lt/api/emails'),
      );

      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      request.fields['sender'] = _toController.text;
      request.fields['subject'] = _subjectController.text;
      request.fields['body'] = _bodyController.text;

      for (var file in attachedFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments[]',
              file.path!,
              filename: file.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Mail erfolgreich versendet!')),
          );
        }
      } else {
        throw Exception('Server antwortete mit Fehler: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden der E-Mail')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Neue Nachricht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Anhang hinzufügen',
            onPressed: _pickFiles,
          ),
          IconButton(
            icon: Icon(isPreviewMode ? Icons.edit : Icons.remove_red_eye),
            tooltip: isPreviewMode ? 'Bearbeiten' : 'Vorschau',
            onPressed: () {
              setState(() {
                isPreviewMode = !isPreviewMode;
              });
            },
          ),
          IconButton(
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: isSending ? null : _sendEmail,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'An',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Bitte gültige E-Mail eingeben'
                    : null,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Betreff',
                  border: InputBorder.none,
                ),
                validator: (value) => value!.isEmpty ? 'Betreff fehlt' : null,
              ),
            ),
            const Divider(height: 1),
            if (attachedFiles.isNotEmpty) ...[
              Container(
                height: 50,
                color: isDark ? Colors.grey[800] : Colors.grey.shade100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachedFiles.length,
                  itemBuilder: (context, index) {
                    final file = attachedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        top: 8.0,
                        bottom: 8.0,
                      ),
                      child: Chip(
                        label: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          setState(() {
                            attachedFiles.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            if (!isPreviewMode) ...[
              Container(
                color: isDark ? Colors.grey[850] : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.format_bold,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('**', '**'),
                      tooltip: 'Fett',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_italic,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('*', '*'),
                      tooltip: 'Kursiv',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_list_bulleted,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('- '),
                      tooltip: 'Liste',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code, color: Colors.black54),
                      onPressed: () => _insertMarkdown('`', '`'),
                      tooltip: 'Code',
                    ),
                    IconButton(
                      icon: const Icon(Icons.link, color: Colors.black54),
                      onPressed: () => _insertMarkdown('[', '](url)'),
                      tooltip: 'Link',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.table_chart_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown(
                        '\n| Kopf 1 | Kopf 2 | Kopf 3 |\n| :--- | :--- | :--- |\n| Wert 1 | Wert 2 | Wert 3 |\n| Wert 4 | Wert 5 | Wert 6 |\n',
                      ),
                      tooltip: 'Tabelle',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: isPreviewMode
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.grey.shade50,
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: _bodyController.text.isEmpty
                              ? '*Kein Text eingegeben*'
                              : _bodyController.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          hintText:
                              'Nachricht schreiben (Markdown unterstützt)',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        validator: (value) => value!.isEmpty
                            ? 'Nachricht darf nicht leer sein'
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
