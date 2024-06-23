import os

path = input("Enter The Directory:")
list = os.listdir(path)
for file in list:
    if file.endswith(".log"):
        print(file)
    else:
        print("No file with Extn .log")

