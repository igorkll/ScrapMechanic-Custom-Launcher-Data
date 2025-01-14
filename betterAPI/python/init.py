import sys
sys.path.append("python/libs")

"""
codeStr = ""
while True:
   codeStr = codeStr + input()
   if codeStr[-1] == "\0":
      codeStr = codeStr[0:-1]
      break
   codeStr = codeStr + "\n"
"""

with open(sys.argv[1], "r") as f:
   codeStr = f.read()
   exec(codeStr)