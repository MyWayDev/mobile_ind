import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:mor_release/models/area.dart';
import 'package:mor_release/models/user.dart';
import 'package:mor_release/scoped/connected.dart';
import 'package:mor_release/widgets/color_loader_2.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:groovin_material_icons/groovin_material_icons.dart';

import 'package:intl/intl.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

class NewMemberPage extends StatefulWidget {
  //final List<Area> areas;
  // NewMemberPage(this.areas);
  State<StatefulWidget> createState() {
    return _NewMemberPage();
  }
}

//final FirebaseDatabase dataBase = FirebaseDatabase.instance;
@override
class _NewMemberPage extends State<NewMemberPage> {
  DateTime selected;
  String path = 'flamelink/environments/stage/content/areas/id/';
  FirebaseDatabase database = FirebaseDatabase.instance;
  TextEditingController controller = new TextEditingController();

  final GlobalKey<FormState> _newMemberFormKey = GlobalKey<FormState>();
  List<DropdownMenuItem> items = [];
  String selectedValue;
  var areaSplit;
  @override
  void initState() {
    super.initState();
    getAreas();
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  _showDateTimePicker(String userId) async {
    selected = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2050));
    // locale: Locale('fr'));
    setState(() {});
  }

  //final model = MainModel();
  void getAreas() async {
    DataSnapshot snapshot = await database.reference().child(path).once();

    Map<dynamic, dynamic> _areas = snapshot.value;
    List list = _areas.values.toList();
    List<Area> fbAreas = list.map((f) => Area.json(f)).toList();

    if (snapshot.value != null) {
      for (var t in fbAreas) {
        String sValue = "${t.areaId}" + " " + "${t.name}";
        items.add(DropdownMenuItem(
            child: Text(
              sValue,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            value: sValue));
      }
    }
  }

  final NewMember _newMemberForm = NewMember(
    sponsorId: null,
    familyName: null,
    name: null,
    personalId: null,
    birthDate: null,
    email: null,
    telephone: null,
    address: null,
    areaId: null,
  );

  Area stateValue;

  bool _isloading = false;

  void isloading(bool i) {
    setState(() {
      _isloading = i;
    });
  }

  bool veri = false;
  //int _courier;
  User _nodeData;

  void resetVeri() {
    controller.clear();
    setState(() {
      veri = false;
    });
  }

  bool validData;
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  bool validateAndSave(String userId) {
    final form = _newMemberFormKey.currentState;
    isloading(true);
    if (form.validate() && selected != null && areaSplit.first != null) {
      _newMemberForm.birthDate =
          DateFormat('yyyy-MM-dd').format(selected).toString();
      _newMemberForm.email = userId;
      setState(() {
        validData = true;
      });
      // isloading(true);
      print('valide entry $validData');
      _newMemberFormKey.currentState.save();

      print('${_newMemberForm.sponsorId}:${_newMemberForm.birthDate}');
      isloading(false);
      return true;
    }
    isloading(false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: ModalProgressHUD(
          child: Container(
            child: buildRegForm(context),
          ),
          inAsyncCall: _isloading,
          opacity: 0.6,
          progressIndicator: ColorLoader2(),
        ),
      );
    });
  }

  Widget buildRegForm(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return Container(
        child: Form(
          key: _newMemberFormKey,
          child: ListView(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.only(left: 8),
                            leading: Icon(Icons.vpn_key,
                                size: 25.0, color: Colors.pink[500]),
                            title: TextFormField(
                              textAlign: TextAlign.center,
                              controller: controller,
                              enabled: !veri ? true : false,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: ' Masukkan ID sponsor',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value.isEmpty
                                  ? 'Code is Empty !!'
                                  : RegExp('[0-9]').hasMatch(value)
                                      ? null
                                      : 'invalid code !!',
                              onSaved: (_) {
                                _newMemberForm.sponsorId = _nodeData.distrId;
                              },
                            ),
                            trailing: IconButton(
                              icon: !veri && controller.text.length > 0
                                  ? Icon(
                                      Icons.check,
                                      size: 30.0,
                                      color: Colors.blue,
                                    )
                                  : controller.text.length > 0
                                      ? Icon(
                                          Icons.close,
                                          size: 28.0,
                                          color: Colors.grey,
                                        )
                                      : Container(),
                              color: Colors.pink[900],
                              onPressed: () async {
                                if (!veri) {
                                  veri = await model.leaderVerification(
                                      controller.text.padLeft(8, '0'));
                                  if (veri) {
                                    _nodeData = await model.nodeJson(
                                        controller.text.padLeft(8, '0'));
                                    controller.text = _nodeData.distrId +
                                        '    ' +
                                        _nodeData.name;
                                  } else {
                                    resetVeri();
                                  }
                                } else {
                                  resetVeri();
                                }
                              },
                              splashColor: Colors.pink,
                            ),
                          ),
                          veri
                              ? Container(
                                  child: Column(
                                    children: <Widget>[
                                      ListTile(
                                        leading: RawMaterialButton(
                                          child: Icon(
                                            GroovinMaterialIcons.calendar_check,
                                            size: 26.0,
                                            color: Colors.white,
                                          ),
                                          shape: CircleBorder(),
                                          highlightColor: Colors.pink[500],
                                          elevation: 8,
                                          fillColor: Colors.pink[500],
                                          onPressed: () {
                                            _showDateTimePicker(
                                                model.userInfo.distrId);
                                          },
                                          splashColor: Colors.pink[900],
                                        ),
                                        title: selected != null
                                            ? Text(DateFormat('yyyy-MM-dd')
                                                .format(selected)
                                                .toString())
                                            : Text(''),
                                        subtitle: Padding(
                                          padding: EdgeInsets.only(right: 10),
                                          child: selected == null
                                              ? Text('Tanggal lahir')
                                              : Text(''),
                                        ),

                                        //trailing:
                                      ),
                                      Divider(
                                        height: 6,
                                        color: Colors.black,
                                      ),
                                      /*  TextFormField(
                                    decoration: InputDecoration(
                                        labelText: 'الاسم العائلي',
                                        contentPadding: EdgeInsets.all(8.0),
                                        icon: Icon(
                                            GroovinMaterialIcons.format_size,
                                            color: Colors.pink[500])),
                                    validator: (value) {},
                                    keyboardType: TextInputType.text,
                                    onSaved: (String value) {
                                      _newMemberForm.familyName = value;
                                    },
                                  ),*/
                                      TextFormField(
                                        autovalidate: true,
                                        decoration: InputDecoration(
                                            labelText: 'Nama',
                                            contentPadding: EdgeInsets.all(8.0),
                                            icon: Icon(
                                                GroovinMaterialIcons
                                                    .format_title,
                                                color: Colors.pink[500])),
                                        validator: (value) {
                                          String _msg;
                                          value.length < 9
                                              ? _msg = 'Nama anggota tidak valid'
                                              : _msg = null;
                                          return _msg;
                                        },
                                        keyboardType: TextInputType.text,
                                        onSaved: (String value) {
                                          _newMemberForm.name = value;
                                        },
                                      ),
                                      TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Nomor tanda pengenal',
                                            contentPadding: EdgeInsets.all(8.0),
                                            icon: Icon(Icons.assignment_ind,
                                                color: Colors.pink[500])),
                                        validator: (value) {
                                          String _msg;
                                          value.length < 5
                                              ? _msg = 'خطأ فى حفظ الرقم الوطنى'
                                              : _msg = null;
                                          return _msg;
                                        },
                                        autocorrect: true,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        keyboardType: TextInputType.text,
                                        onSaved: (String value) {
                                          _newMemberForm.personalId = value;
                                        },
                                      ),
                                      TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Nomor telepon',
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.all(8.0),
                                            icon: Icon(
                                              Icons.phone,
                                              color: Colors.pink[500],
                                            )),
                                        validator: (value) {
                                          String _msg;
                                          value.length < 8
                                              ? _msg = ' خطأ فى حفظ  الهاتف'
                                              : _msg = null;
                                          return _msg;
                                        },
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                signed: true),
                                        onSaved: (String value) {
                                          _newMemberForm.telephone = value;
                                        },
                                      ),
                                      /*  TextFormField(
                                    decoration: InputDecoration(
                                        labelText: 'Surel',
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: EdgeInsets.all(8.0),
                                        icon: Icon(
                                          Icons.email,
                                          color: Colors.pink[500],
                                        )),
                                    keyboardType: TextInputType.emailAddress,
                                    onSaved: (String value) {
                                      _newMemberForm.email = value;
                                    },
                                  ),*/
                                      TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Alamat',
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding: EdgeInsets.all(8.0),
                                            icon: Icon(
                                              GroovinMaterialIcons.home,
                                              color: Colors.pink[500],
                                            )),
                                        validator: (value) {
                                          String _msg;
                                          value.length < 9
                                              ? _msg = 'خطأ فى حفظ العنوان'
                                              : _msg = null;
                                          return _msg;
                                        },
                                        keyboardType: TextInputType.text,
                                        onSaved: (String value) {
                                          _newMemberForm.address = value;
                                        },
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.add_location,
                                            size: 28,
                                            color: Colors.pink[500],
                                          ),
                                          SearchableDropdown(
                                            hint: Text('Area'),
                                            icon: Icon(
                                              Icons.arrow_drop_down_circle,
                                              size: 30,
                                            ),
                                            iconEnabledColor: Colors.pink[200],
                                            iconDisabledColor: Colors.grey,
                                            items: items,
                                            value: selectedValue,
                                            onChanged: (value) {
                                              setState(() {
                                                selectedValue = value;
                                                areaSplit =
                                                    selectedValue.split('\ ');
                                                _newMemberForm.areaId =
                                                    areaSplit.first;
                                                print(
                                                    'split:${_newMemberForm.areaId}');
                                              });
                                            },
                                          ),
                                        ],
                                      )

                                      /*FormField<Area>(
                                    initialValue: _newMemberForm.areaId = null,
                                    onSaved: (val) =>
                                        _newMemberForm.areaId = val.areaId,
                                    validator: (val) => (val == null)
                                        ? 'Please choose a area'
                                        : null,
                                    builder: (FormFieldState<Area> state) {
                                      return InputDecorator(
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          icon: Icon(
                                            GroovinMaterialIcons
                                                .map_marker_radius,
                                            color: Colors.pink[500],
                                          ),
                                          labelText: stateValue == null
                                              ? 'Wilaya'
                                              : '',
                                          errorText: state.hasError
                                              ? state.errorText
                                              : null,
                                        ),
                                        isEmpty: state.value == null,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<Area>(
                                            // iconSize: 25.0,
                                            // elevation: 5,
                                            value: stateValue,
                                            // isDense: true,
                                            onChanged: (Area newValue) async {
                                              if (newValue.areaId == '') {
                                                newValue = null;
                                              }
                                              setState(() {
                                                stateValue = newValue;
                                              });

                                              state.didChange(newValue);

                                              print('AreaId${newValue.areaId}');
                                            },
                                            items:
                                                widget.areas.map((Area area) {
                                              return DropdownMenuItem<Area>(
                                                value: area,
                                                child: Text(
                                                  area.name,
                                                  style: TextStyle(
                                                    color: Colors.pink[900],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),*/
                                    ],
                                  ),
                                )
                              : Container()
                        ]),
                  ),
                ),
              ),
              veri
                  ? Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(right: 10.0),
                          ),
                          Expanded(
                            child: IconButton(
                              icon: Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.greenAccent[400],
                                  size: 65,
                                ),
                              ),
                              onPressed: () async {
                                String msg = '';
                                if (validateAndSave(model.userInfo.distrId)) {
                                  msg = await _saveNewMember(
                                      model.userInfo.distrId);
                                  showReview(context, msg);

                                  _newMemberFormKey.currentState.reset();
                                }

                                //  s

                                //_newMemberFormKey.currentState.reset();
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      );
    });
  }

  String errorM = '';
  Future<String> _saveNewMember(String user) async {
    Id body;
    String msg;
    isloading(true);
    print(_newMemberForm.postNewMemberToJson(_newMemberForm));
    Response response = await _newMemberForm.createPost(_newMemberForm, user);
    if (response.statusCode == 201) {
      body = Id.fromJson(json.decode(response.body));
      msg = body.id;
      print("body.id${body.id}");
    } else {
      msg = "Kesalahan menyimpan data";
    }
    print(response.statusCode);
    print(msg);
    isloading(false);

    return msg;
  }

  Future<bool> showReview(BuildContext context, String msg) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Container(
              height: 110.0,
              width: 110.0,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20.0)),
              child: Column(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        ' Nomor yang menyala: $msg ',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/bottomnav', (_) => false);
                    },
                    child: Container(
                      height: 35.0,
                      width: 35.0,
                      color: Colors.white,
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
/*
  void _regPressed() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (validateAndSave()) {
      await initlegacyData(_registrationFormData['userId'])
          .catchError((e) => '');
      await fireData(_registrationFormData['userId']).catchError((e) => '');
      if (!_legacyDataExits || _fireDataExits) {
        errorM = 'wrong code';
        print('legacyDataExits:$_legacyDataExits');
        print('fireDataExits:$_fireDataExits');
        isloading(false);
        print(errorM);
      } else {
        print('legacyDataExits:$_legacyDataExits');
        print('fireDataExits:$_fireDataExits');
        errorM = 'Good to GO';
        print(errorM);
        validateAndSubmit();
      }
    }
        TextFormField(
                        decoration: InputDecoration(
                            labelText: 'ID sponsor',
                            contentPadding: EdgeInsets.all(8.0),
                            icon: Icon(Icons.vpn_key, color: Colors.pink[500])),
                        //autocorrect: true,
                        autofocus: true,
                        //autovalidate: true,
                        // initialValue: '00000000',
                        validator: (value) => value.isEmpty
                            ? 'ID member !!'
                            : RegExp('[0-9]').hasMatch(value)
                                ? null
                                : 'ID member !!',

                        keyboardType: TextInputType.number,
                        onSaved: (String value) {
                          _newMemberFormData['sponsorId'] =
                              value.padLeft(8, '0');
                        },
                      ),
  }*/
}

class Id {
  String id;

  Id({this.id});

  factory Id.fromJson(Map<String, dynamic> json) {
    return Id(id: json['id']);
  }
}
