import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_task_v1_app/models/task.dart';
import 'package:flutter_task_v1_app/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class UpdateDeleteTask extends StatefulWidget {
  final Task task;

  const UpdateDeleteTask({
    super.key,
    required this.task,
  });

  @override
  State<UpdateDeleteTask> createState() => _UpdateDeleteTaskState();
}

class _UpdateDeleteTaskState extends State<UpdateDeleteTask> {
  // สร้างตัวควบคุม TextField และตัวแปรที่จะต้องเก็บข้อมูลที่ผู้ใช้ป้อนหรือเลือก เพื่อบันทึกใน task_tb
  TextEditingController taskNameCtrl = TextEditingController();
  TextEditingController taskWhereCtrl = TextEditingController();
  TextEditingController taskPersonCtrl = TextEditingController();
  bool taskStatus = false;
  TextEditingController taskDuedateCtrl = TextEditingController();
  String? taskImageUrl = '';

    //ตัวแปรเก็บไฟล์ที่ใช้อัปโหลดไปยัง task_bk
  File? file;
 
  //---- เปิดกลองถ่ายภาพ และกำหนดค่ารูปเพื่อ upload ----
  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.camera); //.gallery
 
    if (picked != null) {
      setState(() {
        file = File(picked.path);
      });
    }
  }
  //-----------------------------------------------
   //---- เปิดปฏิทันเลือกวันที่ และกำหนดค่าวันที่ ----
  DateTime? selectedDate;
 
  Future<void> pickDate() async {
    //เปิดปฏิทิน
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
 
    //เอาค่าวันที่เลือกจากปฏิทินไปกำหนดให้กับ taskDuedateCtrl
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        taskDuedateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  //-------------------------
  //---- เมธอดอัปโหลดไฟล์ และบันทึกแก้ไขข้อมูลจากการกดปุ่มบันทึก ----
Future<void> update() async {
  //validate ข้อมูลที่ผู้ใช้ป้อนหรือเลือกก่อนว่าไม่เป็นค่าว่าง
   if (taskNameCtrl.text.isEmpty ||
        taskWhereCtrl.text.isEmpty ||
        taskPersonCtrl.text.isEmpty ||
        taskDuedateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาป้อนข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
 
      return; //*** อย่าลืม return เพื่อไม่ให้ทำงานต่อ หรือ ให้ออกจากการทำงานของเมธอดนี้เลย
    }
     // สร้าง instance/object/ตัวแทน ของ SupabaseService เพื่อใช้งานเมธอดต่างๆ ที่สร้างไว้ใน SupabaseService
    final service = SupabaseService();
    // ตรวจสอบว่ามีการถ่าย/เลือกรูปหรือไม่ ถ้ามีก็อัปโหลดไฟล์ ไปที่ task_bk
    // แล้วเอา URL ของไฟล์ที่อัปโหลดเก็บในตัวแปรเพื่อใช้บันทึกใน task_tb
    if (file != null) {
      //ต้องตรวจสอบก่อนว่า task มีรูปไหม ถ้ามีรูปต้องลบรูปเก่าออกจาก task_bk ก่อน เพื่อไม่ให้มีไฟล์ที่ไม่ได้ใช้งานเก็บอยู่ใน task_bk เยอะเกินไป
      if(widget.task.task_image_url != null && widget.task.task_image_url != ''){//ถ้า task มีรูป ต้องลบรูปเก่าออกจาก task_bk ก่อน
        await service.deleteFile(widget.task.task_image_url!);
      }
      //หาก file ไม่เท่ากับ null แปลว่าได้มีการถ่าย/เลือกรูป
      //อัปโหลดไฟล์ไปยัง task_bk
      taskImageUrl = await service.uploadFile(file!);
    }
     // บันทึกแก้ไขข้อมูลลง task_tb
    // แพ็กข้อมูล
    final task = Task(
      task_name: taskNameCtrl.text,
      task_where: taskWhereCtrl.text,
      task_person: int.parse(taskPersonCtrl.text),
      task_status: taskStatus,
      task_duedate: taskDuedateCtrl.text,
      task_image_url: taskImageUrl,
    
    );
    // เรียกใช้เมธอด insertTask ที่สร้างไว้ใน SupabaseService เพื่อบันทึกข้อมูลลง task_tb
    await service.updateTask(widget.task.id!, task);
    // กลับไปหน้าแรก และรีเฟรชข้อมูล // แจ้งผลการทำงาน (แสดงเป็น SnackBar หรือ AlertDialog ก็ได้)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกข้อมูลสำเร็จ'),
        backgroundColor: const Color.fromARGB(255, 243, 228, 69),
        duration: Duration(seconds: 2),
      ),
    );
 
    // ย้อนกลับไปยังหน้าหลัก ShowAllTaskUi
    Navigator.pop(context);

}

//---- เมธอดลบข้อมูลจากการกดปุ่มลบ ----

Future<void> delete() async {
 //แสดงป็อปอัพถามผู้ใช้ก่อนเพื่อยืนยันการลบ
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ยืนยันการลบ'),
      content: Text('คุณต้องการลบงานนี้หรือไม่?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('ลบ'),
        ),
      ],
    ),
  );
 
  if (confirm == true) {
    // สร้าง instance/object/ตัวแทน ของ SupabaseService เพื่อใช้งานเมธอดต่างๆ ที่สร้างไว้ใน SupabaseService
    final service = SupabaseService();
    // ลบข้อมูลจาก task_tb โดยเรียกใช้เมธอด deleteTask ที่สร้างไว้ใน SupabaseService
    await service.deleteTask(widget.task.id!);
    // หากมีรูปภาพที่เกี่ยวข้องกับงานนี้ก็ให้ลบรูปภาพนั้นออกจาก task_bk ด้วย
    if(widget.task.task_image_url != null && widget.task.task_image_url != ''){//ถ้า task มีรูป ต้องลบรูปออกจาก task_bk ด้วย
      await service.deleteFile(widget.task.task_image_url!);
    }
     // กลับไปหน้าแรก และรีเฟรชข้อมูล // แจ้งผลการทำงาน (แสดงเป็น SnackBar หรือ AlertDialog ก็ได้)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบข้อมูลสำเร็จ'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
 
    // ย้อนกลับไปยังหน้าหลัก ShowAllTaskUi
    Navigator.pop(context);
  }
}
@override

  void initState() {
    // TODO: implement initState
    super.initState();
    taskNameCtrl.text = widget.task.task_name!;
    taskWhereCtrl.text = widget.task.task_where!;
    taskPersonCtrl.text = widget.task.task_person!.toString();
    taskDuedateCtrl.text = widget.task.task_duedate!;
    taskStatus = widget.task.task_status == 1;
    taskImageUrl = widget.task.task_image_url;

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 209, 41),
        title: Text(
          'Task Na Ja V.1 (แก้ไข/ลบ)',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: 30,
            left: 45,
            right: 45,
            bottom: 50,
          ),
          child: Center(
            child: Column(
              children: [
                // ส่วนแสดงรูปและรูปกล้องเพื่อเปิดกล้อง
                //file == null
                file !=  null
                ? InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Image.file(
                            file!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover
                          ),
                       
                      )
                : taskImageUrl == ''
                    ? InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Image.asset(
                            'assets/images/work-order.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover
                          ),
                       
                      )
                    : InkWell(
                        onTap: () {
                          pickImage();
                        },
                        child: Image.network(
                          taskImageUrl!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                // ป้อนทำอะไร
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ทำอะไร',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: taskNameCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น ซักผ้า, ซ่อมหลอดไฟ',
                  ),
                ),
                SizedBox(height: 20),
                // ป้อนทำที่ไหน
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ทำที่ไหน',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: taskWhereCtrl,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น บ้าน, ที่ทำงาน',
                  ),
                ),
                SizedBox(height: 20),
                // ป้อนทำกันกี่คน
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ทำกันกี่คน',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: taskPersonCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น 2, 5',
                  ),
                ),
                SizedBox(height: 20),
                // เลือกทำเสร็จหรือยัง
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ทำเสร็จหรือยัง',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          taskStatus = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            taskStatus == true ? const Color.fromARGB(255, 255, 209, 41): Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        fixedSize: Size(
                          MediaQuery.of(context).size.width * 0.35,
                          50,
                        ),
                      ),
                      child: Text(
                        'เสร็จแล้ว',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          taskStatus = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            taskStatus == false ? const Color.fromARGB(255, 255, 209, 41): Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        fixedSize: Size(
                          MediaQuery.of(context).size.width * 0.35,
                          50,
                        ),
                      ),
                      child: Text(
                        'ยังไม่เสร็จ',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // เลือกต้องเสร็จเมื่อไหร่
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'เสร็จเมื่อไหร่',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
                TextField(
                  controller: taskDuedateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    hintText: 'เช่น 2020-01-31',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () {
                    pickDate();
                  },
                ),
                SizedBox(height: 20),
                // ปุ่มบันทึกแก้ไข
                ElevatedButton(
                  onPressed: () {
                    //เรียกใช้เมธอดอัพเดต เพื่อบันทึกแแก้ไขข้อมูลลงในฐานข้อมูล
                    update();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 209, 41),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      50,
                    ),
                  ),
                  child: Text(
                    "บันทึก",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // ปุ่มลบ
                ElevatedButton(
                  onPressed: () {
                   //ลบข้อมูลจากการกดปุ่มลบ
                    delete().then((value) {
                      //หลังจากลบข้อมูลเสร็จแล้วให้ย้อนกลับไปยังหน้าหลัก ShowAllTaskUi
                      Navigator.pop(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    fixedSize: Size(
                      MediaQuery.of(context).size.width,
                      50,
                    ),
                  ),
                  child: Text(
                    "ลบ",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}