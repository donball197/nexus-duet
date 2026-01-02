import tkinter as tk

class CalculatorApp:
    def __init__(self, master):
        self.master = master
        master.title("Simple Calculator")

        # Entry widget to display numbers and results
        self.entry = tk.Entry(master, width=35, borderwidth=5, font=('Arial', 16))
        self.entry.grid(row=0, column=0, columnspan=4, padx=10, pady=10)

        # Initialize calculator state
        self.current_number = ""
        self.first_num = None
        self.operator = None
        self.new_calculation = True # Flag to clear entry for new number

        # Create buttons
        self.create_buttons()

    def create_buttons(self):
        # Define button layout
        buttons = [
            ('7', 1, 0), ('8', 1, 1), ('9', 1, 2), ('/', 1, 3),
            ('4', 2, 0), ('5', 2, 1), ('6', 2, 2), ('*', 2, 3),
            ('1', 3, 0), ('2', 3, 1), ('3', 3, 2), ('-', 3, 3),
            ('0', 4, 0), ('.', 4, 1), ('=', 4, 2), ('+', 4, 3),
        ]

        for (text, row, col) in buttons:
            if text == '=':
                button = tk.Button(self.master, text=text, padx=30, pady=20, font=('Arial', 14),
                                   command=self.equals_button_click)
            elif text in ('/', '*', '-', '+'):
                button = tk.Button(self.master, text=text, padx=30, pady=20, font=('Arial', 14),
                                   command=lambda t=text: self.operator_button_click(t))
            else:
                button = tk.Button(self.master, text=text, padx=30, pady=20, font=('Arial', 14),
                                   command=lambda t=text: self.number_button_click(t))
            button.grid(row=row, column=col, padx=5, pady=5)

        # Clear button
        clear_button = tk.Button(self.master, text="Clear", padx=68, pady=20, font=('Arial', 14),
                                 command=self.clear_button_click)
        clear_button.grid(row=5, column=0, columnspan=2, padx=5, pady=5)

        # Backspace button
        back_button = tk.Button(self.master, text="<-", padx=30, pady=20, font=('Arial', 14),
                                command=self.backspace_button_click)
        back_button.grid(row=5, column=2, columnspan=1, padx=5, pady=5)


    def number_button_click(self, number):
        if self.new_calculation:
            self.entry.delete(0, tk.END)
            self.new_calculation = False
        current_text = self.entry.get()
        self.entry.delete(0, tk.END)
        self.entry.insert(0, current_text + str(number))

    def operator_button_click(self, op):
        try:
            self.first_num = float(self.entry.get())
            self.operator = op
            self.new_calculation = True # Ready for the second number
        except ValueError:
            self.entry.delete(0, tk.END)
            self.entry.insert(0, "Error")

    def equals_button_click(self):
        if self.first_num is None or self.operator is None:
            return # Nothing to calculate yet

        try:
            second_num = float(self.entry.get())
            result = 0

            if self.operator == '+':
                result = self.first_num + second_num
            elif self.operator == '-':
                result = self.first_num - second_num
            elif self.operator == '*':
                result = self.first_num * second_num
            elif self.operator == '/':
                if second_num == 0:
                    result = "Error! Div by 0"
                else:
                    result = self.first_num / second_num

            self.entry.delete(0, tk.END)
            # Format float results to avoid excessive decimal places if it's a whole number
            if isinstance(result, float) and result == int(result):
                self.entry.insert(0, str(int(result)))
            else:
                self.entry.insert(0, str(result))

            self.first_num = None
            self.operator = None
            self.new_calculation = True # Result is displayed, ready for new input
        except ValueError:
            self.entry.delete(0, tk.END)
            self.entry.insert(0, "Error")
        except Exception as e:
            self.entry.delete(0, tk.END)
            self.entry.insert(0, f"Error: {e}")

    def clear_button_click(self):
        self.entry.delete(0, tk.END)
        self.first_num = None
        self.operator = None
        self.new_calculation = True

    def backspace_button_click(self):
        current_text = self.entry.get()
        if current_text:
            self.entry.delete(0, tk.END)
            self.entry.insert(0, current_text[:-1])


# Run the GUI calculator
if __name__ == "__main__":
    root = tk.Tk()
    app = CalculatorApp(root)
    root.mainloop()

