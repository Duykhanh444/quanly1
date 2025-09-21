import 'package:flutter/material.dart';
import '../models/nhanvien.dart';
import '../models/workday.dart';
import 'package:intl/intl.dart';

class ChinhSuaWorkDayScreen extends StatefulWidget {
  final NhanVien nhanVien;

  const ChinhSuaWorkDayScreen({super.key, required this.nhanVien});

  @override
  State<ChinhSuaWorkDayScreen> createState() => _ChinhSuaWorkDayScreenState();
}

class _ChinhSuaWorkDayScreenState extends State<ChinhSuaWorkDayScreen> {
  late List<WorkDay> workDays;

  @override
  void initState() {
    super.initState();

    workDays = widget.nhanVien.workDays.isNotEmpty
        ? List.from(widget.nhanVien.workDays)
        : List.generate(6, (i) {
            final now = DateTime.now();
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            return WorkDay(
              id: 0,
              ngay: startOfWeek.add(Duration(days: i)),
              soGio: 8,
            );
          });
  }

  void luuThayDoi() {
    Navigator.pop(context, workDays);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE dd/MM', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa giờ làm'),
        actions: [
          IconButton(onPressed: luuThayDoi, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView.builder(
        itemCount: workDays.length,
        itemBuilder: (context, index) {
          final wd = workDays[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(dateFormat.format(wd.ngay)),
              subtitle: Text('Số giờ: ${wd.soGio}h'),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: wd.soGio.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giờ',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final gio = int.tryParse(val) ?? 0;
                    setState(() {
                      workDays[index] = WorkDay(
                        id: wd.id,
                        ngay: wd.ngay,
                        soGio: gio,
                      );
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
