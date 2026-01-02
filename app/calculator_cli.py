def add(x, y):
    """Adds two numbers."""
    return x + y

def subtract(x, y):
    """Subtracts two numbers."""
    return x - y

def multiply(x, y):
    """Multiplies two numbers."""
    return x * y

def divide(x, y):
    """Divides two numbers, handles division by zero."""
    if y == 0:
        return "Error! Cannot divide by zero."
    return x / y

def calculator_cli():
    """Runs the command-line calculator."""
    print("Welcome to the Simple CLI Calculator!")
    print("Select operation:")
    print("1. Add (+)")
    print("2. Subtract (-)")
    print("3. Multiply (*)")
    print("4. Divide (/)")
    print("Enter 'exit' to quit.")

    while True:
        choice = input("\nEnter choice(1/2/3/4) or 'exit': ").lower()

        if choice == 'exit':
            print("Exiting calculator. Goodbye!")
            break

        if choice in ('1', '2', '3', '4', '+', '-', '*', '/'):
            try:
                num1 = float(input("Enter first number: "))
                num2 = float(input("Enter second number: "))
            except ValueError:
                print("Invalid input. Please enter numbers only.")
                continue

            operator_symbol = ''
            if choice == '1' or choice == '+':
                operator_symbol = '+'
                result = add(num1, num2)
            elif choice == '2' or choice == '-':
                operator_symbol = '-'
                result = subtract(num1, num2)
            elif choice == '3' or choice == '*':
                operator_symbol = '*'
                result = multiply(num1, num2)
            elif choice == '4' or choice == '/':
                operator_symbol = '/'
                result = divide(num1, num2)

            print(f"{num1} {operator_symbol} {num2} = {result}")
        else:
            print("Invalid input. Please enter a valid choice (1/2/3/4) or 'exit'.")

# Run the CLI calculator
if __name__ == "__main__":
    calculator_cli()

