import sys, csv
from collections import defaultdict

count = defaultdict(int)
delim = '\t'

blobs = defaultdict()
seen = defaultdict()

# these are the csid and md5 key of the "restricted media" image in PAHMA's production binary repo
# probably they should not be hardcoded; but I'm not sure how they should be obtained...
restricted_csid = '59a733dd-d641-4e1a-8552'
restricted_md5 = '44f1c5b4d03a07832c32ccce289268ba'

mimetypes = {'application/pdf': 'document',
             'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'document',
             'audio/mpeg': 'audio',
             'audio/aac': 'audio',
             'audio/x-wav': 'audio',
             'image/jpeg': 'image',
             'image/photoshop': 'document',
             'image/png': 'image',
             'image/tiff': 'image',
             'image/x-adobe-dng': 'document',
             'image/x-nikon-nef': 'document',
             'model/x3d+xml': '3D',
             'model/x3d-vrml': '3D',
             'model/x3d+fastinfoset': '3D',
             'video/mp4': 'video'}

runtype = sys.argv[3]  # generate media for public or internal

# nb: these indexes are all offest by 2 -- the list they are used in is sliced
fcpcol = 39
contextofusecol = 13
objectnamecol = 8
objectlegacydeptcol = 2


def check(string_to_check, pattern):
    if str(pattern).lower() in str(string_to_check).lower():
        return True
    else:
        return False


writer = csv.writer(open(sys.argv[4], "w"), delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255), escapechar='\\')

with open(sys.argv[1], 'r') as MEDIA:
    reader = csv.reader(MEDIA, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    for row in reader:

        count['media'] += 1

        # skip header row
        if count['media'] == 1:
            continue

        if len(row) != 19:
            print('expected 19 columns:')
            print(row)
            count['skipped media (invalid row)'] += 1
            continue
        (objectcsid, objectnumber, mediacsid, description, name, creatorrefname, creator, blobcsid, copyrightstatement,
         identificationnumber, rightsholderrefname, rightsholder, contributor, approvedforweb, pahmatmslegacydepartment,
         objectstatus, primarydisplay, mimetype, md5) = row
        count['primary display %s' % primarydisplay] += 1
        count['mimetype %s' % mimetype] += 1
        if mimetype in mimetypes:
            media_available = mimetypes[mimetype]
        else:
            media_available = 'other media'

        if media_available == 'image':
            media_type = 'images'
        else:
            media_type = 'other media'
        # mark catalog card images as such
        if check(description, 'catalog card') or check(description, 'HSR Datasheet'): media_type = 'legacy documentation'
        if check(description, 'Index'): media_type = 'legacy documentation'
        ispublic = 'public'
        if check(objectstatus, 'culturally'): ispublic = 'notpublic'
        # NB: the test 'burial' in context of use occurs below -- we only mask if the FCP is in North America
        if not (approvedforweb == 't'): ispublic = 'notpublic'
        if media_type == 'legacy documentation':
            media_available = media_type
        count[media_type] += 1
        count[ispublic] += 1
        count['media available %s' % media_available] += 1

        if not objectcsid in blobs:
            blobs[objectcsid] = defaultdict(int)
            blobs[objectcsid]['legacy documentation'] = []
            blobs[objectcsid]['images'] = []
            blobs[objectcsid]['legacy documentation md5s'] = []
            blobs[objectcsid]['image_md5s'] = []
            blobs[objectcsid]['type'] = []
            blobs[objectcsid]['restrictions'] = []
            blobs[objectcsid]['video_csids'] = []
            blobs[objectcsid]['video_md5s'] = []
            blobs[objectcsid]['video_mimetypes'] = []
            blobs[objectcsid]['audio_csids'] = []
            blobs[objectcsid]['audio_md5s'] = []
            blobs[objectcsid]['audio_mimetypes'] = []
            blobs[objectcsid]['3D_csids'] = []
            blobs[objectcsid]['3D_md5s'] = []
            blobs[objectcsid]['3D_mimetypes'] = []
            blobs[objectcsid]['media_available'] = []
            blobs[objectcsid]['mimetypes'] = []
            blobs[objectcsid]['primary'] = ''
            blobs[objectcsid]['primary_md5'] = ''

        # if this run is to generate the public datastore, use the restricted image if this blob is restricted.
        if runtype == 'public' and ispublic != 'public':
            blobcsid = restricted_csid
            md5 = restricted_md5

        if not check(blobs[objectcsid]['mimetypes'], mimetype):
            blobs[objectcsid]['mimetypes'].append(mimetype)

        if not check(blobs[objectcsid]['media_available'], media_available):
            if ispublic == 'public':
                blobs[objectcsid]['media_available'].append(media_available)

        if media_available in ['audio', 'video', '3D']:
            if ispublic == 'public':
                blobs[objectcsid]['%s_csids' % media_available].append(blobcsid)
                blobs[objectcsid]['%s_md5s' % media_available].append(md5)
                blobs[objectcsid]['%s_mimetypes' % media_available].append(mimetype)

        elif media_type == 'legacy documentation':
            blobs[objectcsid]['legacy documentation'].append(blobcsid)
            blobs[objectcsid]['legacy documentation md5s'].append(md5)

        elif media_type == 'images':
            # add this blob to the list of blobs, unless we somehow already have it (no dups allowed!)
            if not check(blobs[objectcsid]['images'], blobcsid):
                blobs[objectcsid]['hasimages'] = 'yes'
                # put primary images first
                if primarydisplay == 't':
                    blobs[objectcsid]['images'].insert(0, blobcsid)
                    blobs[objectcsid]['image_md5s'].insert(0, md5)
                    blobs[objectcsid]['primary'] = [blobcsid]
                    blobs[objectcsid]['primary_md5'] = [md5]

                else:
                    blobs[objectcsid]['images'].append(blobcsid)
                    blobs[objectcsid]['image_md5s'].append(md5)

        if not check(blobs[objectcsid]['type'], media_type): blobs[objectcsid]['type'].append(media_type)
        if not check(blobs[objectcsid]['restrictions'], ispublic): blobs[objectcsid]['restrictions'].append(ispublic)

# die "couldn't open metadata file sys.arg[1]"

with open(sys.argv[2], 'r') as METADATA:
    reader = csv.reader(METADATA, delimiter=delim, quoting=csv.QUOTE_NONE, quotechar=chr(255))
    for line in reader:
        id = line[0]
        objectcsid = line[1]
        rest = line[2:]
        if objectcsid == '':
            print("objectcsid is blank: ")
            continue
        # handle header line
        if id == 'id':
            header = line + u'blob_ss,blob_md5_ss,card_ss,card_md5_ss,primaryimage_s,primaryimage_md5_s,imagetype_ss,restrictions_ss,hasimages_s,video_csid_ss,video_md5_ss,video_mimetype_ss,audio_csid_ss,audio_md5_ss,audio_mimetype_ss,d3_csid_ss,d3_md5_ss,d3_mimetype_ss,media_available_ss,mimetypes_ss'.split(',')
            writer.writerow(header)
            continue
        count['metadata'] += 1
        mediablobs = line
        if objectcsid in blobs:
            if runtype == 'public':
                # for US sites...
                if check(rest[fcpcol], 'United States') and blobs[objectcsid]['images'] != []:
                    line_as_string = ' '.join(line)
                    # if context of use field contains the word burial
                    # if object name contains something like "charm stone"
                    # belt-and-suspenders: restrict if 'human remains' or charmstone or NAGPRA appear anywhere...
                    if check(rest[contextofusecol], 'burial') or \
                            check(rest[objectnamecol], 'charm stone') or check(rest[objectnamecol], 'charmstone') or \
                            check(rest[objectlegacydeptcol], 'NAGPRA-associated Funerary Objects') or \
                            check(line_as_string, 'Human Remains') or \
                            check(line_as_string, 'charm stone') or check(line_as_string, 'charmstone') or \
                            check(line_as_string, 'NAGPRA-associated Funerary Objects'):

                        # if the *object* is one of the restricted type, remove *all* image media, and use the placeholder
                        blobs[objectcsid]['images'] = [ restricted_csid ]
                        blobs[objectcsid]['image_md5s'] = [ restricted_md5 ]

            # insert list of blobs, etc. as final columns
            if not blobs[objectcsid]['hasimages'] == 'yes': blobs[objectcsid]['hasimages'] = 'no'
            count['hasimages: %s' % blobs[objectcsid]['hasimages']] += 1
            # TODO: fix the type of this field -- it shouldn't have to be a list
            blobs[objectcsid]['hasimages'] = [blobs[objectcsid]['hasimages']]
            # if the object has 3D media, remove any placeholder image that might be been inserted:
            # the texture files for 3D media are of course unpublished, but should not trigger a placeholder
            # HOWEVER, if said object is itself restricted, leave things as they are: there should be a placeholder
            # TODO: but figure out how to distinguish texture images and other images: if the only
            # TODO: images are texture images, we SHOULD eliminate the placeholder!
            if blobs[objectcsid]['3D_csids'] != []:
                blobs[objectcsid]['image_md5s'] = [i for i in blobs[objectcsid]['image_md5s'] if i != restricted_md5]
                blobs[objectcsid]['images'] = [i for i in blobs[objectcsid]['images'] if i != restricted_csid]
            for column in 'images,image_md5s,legacy documentation,legacy documentation md5s,primary,primary_md5,type,restrictions,hasimages,video_csids,video_md5s,video_mimetypes,audio_csids,audio_md5s,audio_mimetypes,3D_csids,3D_md5s,3D_mimetypes,media_available,mimetypes'.split(','):
                mediablobs.append('|'.join(blobs[objectcsid][column]))

            count['object type: ' + ','.join(sorted(blobs[objectcsid]['type']))] += 1
            count['object restrictions: ' + ','.join(sorted(blobs[objectcsid]['restrictions']))] += 1
            count['matched: yes'] += 1
        else:
            count['matched: no'] += 1
            count['hasimages: no'] += 1
            mediablobs += [u''] * 7
            mediablobs += [u'public']
            mediablobs += [u'no']
            mediablobs += [u''] * 11

        for i, m in enumerate(mediablobs):
            if type(m) == type(0):
                count['repaired'] += 1
                mediablobs[i] = str(m)

        writer.writerow(mediablobs)

for s in sorted(count.keys()):
    print("%s: %s" % (s, count[s]))
