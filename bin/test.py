from multiprocessing import Pool
data = [
 {"name": "Delphi"}, {"name": "Orion"}, {"name": "Asher"}, {"name": "Baccus"}
]
def fun(object):
 print(object)

with Pool(4) as pool:
    pool.map(fun,data)
#Prints: """
