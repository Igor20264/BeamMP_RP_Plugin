points = [
    {'x' : 701.71, 'y' : -46.27, 'z' : 53.26, 'name': 'autosalon1'},
    {'x' : 501.38, 'y' : 584.39, 'z' : 50.39, 'name': 'lesopilka1'},
    {'x' : 131.88, 'y' : 16.74, 'z' : 100.51, 'name': 'pojarvishka1'},
    {'x' : -606.37, 'y' : -356.21, 'z' : 34.97, 'name': 'domfermear1'},
    {'x' : -66.02, 'y' : -884.36, 'z' : 14.59, 'name': 'pristan1'},
    {'x' : -307.08, 'y' : -908.51, 'z' : 12.44, 'name': 'osobnak'},
    {'x' : 549.17, 'y' : -758.15, 'z' : 61.16, 'name': 'staryfemer'},
    {'x' : 278.12, 'y' : -758.54, 'z' : 46.74, 'name': 'oldlesopilka'},
    {'x' : -99.24, 'y' : -710.82, 'z' : 29.66, 'name': 'oldhomevlesy'},
    {'x' : -852.49, 'y' : -871.36, 'z' : 37.94, 'name': 'pojarbase'},
    {'x' : -925.11, 'y' : -729.22, 'z' : 35.4, 'name': 'oldhome1'},
    {'x' : -795.95, 'y' : 492.52, 'z' : 24.11, 'name': 'bigzapraka'},
    {'x' : -750.06, 'y' : 539.58, 'z' : 25.65, 'name': 'bigautosalon'},
    {'x' : -341.35, 'y' : -120.05, 'z' : 34.22  ,'name': 'zaprakanewgorod'},
    {'x' : 712.68 , 'y' : -484.85, 'z' : 57.72, 'name': 'gorodhome'},
    {'x' : 785.99 , 'y' : -189.56, 'z' : 53.79, 'name': 'zavodgorod'},
    {'x' : 538.51 , 'y' : -35.97 , 'z' : 53.81, 'name': 'fuelgorod'},
]
for point in points:
    x = point['x']
    y = point['y']
    z = point['z']

    x1 = x+8
    x2 = x-8
    y1 = y+8
    y2 = y+8
    z1 = z-5
    z2 = z+10

    print(f"!geo add_work {point['name']} {x1:.2f} {y1:.2f} {z1:.2f} {x2:.2f} {y2:.2f} {z2:.2f}")