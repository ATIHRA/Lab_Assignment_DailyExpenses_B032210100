import 'package:week10/Controller/request_controller.dart';
import 'Model/expense.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(DailyExpensesApp(username:''));
}

class DailyExpensesApp extends StatelessWidget {

  final String username;
  DailyExpensesApp({required String this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExpenseList(username: username),
    );
  }
}

class ExpenseList extends StatefulWidget {
  final String username;
  ExpenseList({required this.username});

  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final List<Expenses> expenses = [];
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  double totalAmount = 0;

  void _addExpense() async {
    String description = descController.text.trim();
    String amount = amountController.text.trim();

    if (description.isNotEmpty && amount.isNotEmpty) {
      Expenses exp = Expenses(double.parse(amount), description, txtDateController.text);
      if (await exp.save()) {
        setState(() {
          expenses.add(exp);
          descController.clear();
          amountController.clear();
          calculateTotal();
        });
      } else {
        _showMessage("Failed to save expenses data");
      }
    }
  }
  void calculateTotal() {
    totalAmount = 0;
    for(Expenses ex in expenses) {
      totalAmount += ex.amount;
    }
    totalAmountController.text = totalAmount.toString();
  }

  void _removeExpense(int index) {
    totalAmount -= expenses[index].amount;
    setState(() {
      expenses.removeAt(index);
      totalAmountController.text = totalAmount.toString();
    });
  }
//function to display message at bottom of scaffold
  void _showMessage(String msg) {
    if (mounted) {
      //make sure this context is still mounted/exist
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
        ),
      );
    }
  }
  //navigate to edit screen when long press on the itemList
  void _editExpense(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpensesScreen(
          expense: expenses[index],
          onSave: (editedExpense) {
            setState(() {
              totalAmount = totalAmount - expenses[index].amount + editedExpense.amount;
              expenses[index] = editedExpense;
              totalAmountController.text = totalAmount.toString();
            });
          },
        ),
      ),
    );
  }
  //new function - Date and time picker on textField
  _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedDate != null && pickedTime != null) {
      setState(() {
        txtDateController.text =
        "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}"
            "${pickedTime.hour}:${pickedTime.minute}:00";
      });
    }
  }

//username
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _showMessage("Welcome ${widget.username} !!");

      RequestController req = RequestController(
          path: "/api/timezone/Asia/Kuala_Lumpur",
          server: "http://worldtimeapi.org");
      req.get().then((value) {
        dynamic res = req.result();
        txtDateController.text =
            res["datetime"].toString().substring(8,19).replaceAll('T', ' ');
      });
      expenses.addAll(await Expenses.loadAll());

      setState(() {
        calculateTotal();
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Daily Expenses')
      ),
    body: SingleChildScrollView(
    child: Column(
    children: [
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text('Welcome, ${widget.username}'),
    ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.00),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.datetime,
              controller: txtDateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                  labelText: "Date"
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: totalAmountController,
              readOnly: true,
              decoration: InputDecoration(labelText: 'Total Amount Spend (RM)'),
            ),
          ),
          ElevatedButton(
            onPressed: _addExpense,
            child: Text('Add Expense'),
          ),
          Container(
            child: _buildListView(),
          ),
        ],
      ),
    ),);
  }
  Widget _buildListView() {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(expenses[index].amount.toString()), // unique key for each item
            background: Container(
              color: Colors.red,
              child: Center(
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            onDismissed: (direction) {
              // handle item removal here
              _removeExpense(index);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Item dismissed')));
            },
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(expenses[index].desc),
                subtitle: Row(children: [
                  Text('Amount: ${expenses[index].amount}'),
                  const Spacer(),
                  Text('Date: ${expenses[index].dateTime}'),
                ]),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeExpense(index),
                ),
                onLongPress: () {
                  _editExpense(index);
                },
              ),
            ),
          );
        },
      );
  }
}
class EditExpensesScreen extends StatefulWidget {
  final Expenses expense;
  final Function(Expenses) onSave;

  EditExpensesScreen({required this.expense, required this.onSave});

  _EditExpensesScreenState createState() => _EditExpensesScreenState();
}

class _EditExpensesScreenState extends State<EditExpensesScreen> {
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController txtDateController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    descController.text = widget.expense.desc;
    amountController.text = widget.expense.amount.toString();
    //new
    dateTimeController.text = widget.expense.dateTime;
  }

  // widget build method and user interface (UI) here
  @override

  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Expense'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              keyboardType: TextInputType.datetime,
              controller: txtDateController,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: "Date"
              ),
            ),
          ),
        ElevatedButton(
           onPressed: () async {
           double editedAmount = double.parse(amountController.text);

           // Update date and time in the Expense object
             Expenses editedExpense = Expenses(
              editedAmount,
              descController.text,
              dateTimeController.text,
          );
           // Call the onSave callback to update the expense in the parent widget
           widget.onSave(editedExpense);

           // Perform the update to the remote MySQL database
           if (await editedExpense.update()) {
             Navigator.pop(context); // Navigate back after successful update
           } else {
             // Handle update failure
             // You can show an error message or handle it as needed
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Failed to update Expense data'),
               ),
             );
           }
           },
          child: Text('Save'),
        ),
        ],
      ),
    );
  }
}