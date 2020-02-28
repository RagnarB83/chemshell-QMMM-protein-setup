#!/usr/bin/env python3

def delCharges(f1, f2, ilist, i0=1):
    '''
    read in file f1 and output to file f2 with charges i_list set to 0
    f1          read file
    f2          written file
    i_list      list of integers with charges to set to 0
    i0          default 1 (chemshell counting, vmd starts with 0)
    '''

    with open(f1, 'r') as fin:
        with open(f2, 'w') as fout: 
            for line in fin:
                if line.startswith('set charges'):
                    l = line.split()
                    print('Modifying charges in {}. Old charges in {}.'.format(f2, f1),
                        'Counting indices starts with {}.'.format(i0)) 
                    for i in ilist:
                        j = i + 3 - i0
                        if j < 3 or j > len(l) - 2:
                            print('    ERROR: Index {} out of range'.format(i))
                        else:
                            l[i + 3 - i0] = '0.000000' 
                            print('    MM charge for {:7d} is now 0.000000'.format(i))
                        line_new = ' '.join(l) + '\n'
                    fout.write(line_new)
                else:
                    fout.write(line)

if __name__ == "__main__":
    import argparse, os
    
    # parse arguments
    parser = argparse.ArgumentParser(description='Set charges in save-new.chm file to zero')
    parser.add_argument('chm', metavar='chm-file',
        help='"save-new.chm"-like file containing the MM charges')
    parser.add_argument('ilist', metavar='I', type=int, nargs='+',
        help='Indices for which to set the charge to zero')
    parser.add_argument('-b', metavar='BACKUPFILE', 
        help='Name of backup file. Default: old-*.chm')
    parser.add_argument('-c', metavar='I0', type=int, default=1,
        help='''Number with which index counting starts.
        Chemshell starts with 1 (default). VMD starts with 0''')
    args = parser.parse_args()

    # define variables
    chm = args.chm
    if args.b:
        bak = args.b
    else:
        bak = 'old-' + chm
    ilist = args.ilist
    i0 = args.c

    # move chm to backup file
    os.rename(chm, bak)

    # read in backup file and write changes to new chm
    delCharges(bak, chm, ilist, i0=i0)
