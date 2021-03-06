#include <memory.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <fcntl.h>
#include <iostream>
#include <stdio.h>
#include "page.h"
#include "buf.h"

#define ASSERT(c)  { if (!(c)) { \
		       cerr << "At line " << __LINE__ << ":" << endl << "  "; \
                       cerr << "This condition should hold: " #c << endl; \
                       exit(1); \
		     } \
                   }

//----------------------------------------
// Constructor of the class BufMgr
//----------------------------------------

BufMgr::BufMgr(const int bufs)
{
    numBufs = bufs;

    bufTable = new BufDesc[bufs];
    memset(bufTable, 0, bufs * sizeof(BufDesc));
    for (int i = 0; i < bufs; i++) 
    {
        bufTable[i].frameNo = i;
        bufTable[i].valid = false;
    }

    bufPool = new Page[bufs];
    memset(bufPool, 0, bufs * sizeof(Page));

    int htsize = ((((int) (bufs * 1.2))*2)/2)+1;
    hashTable = new BufHashTbl (htsize);  // allocate the buffer hash table

    clockHand = bufs - 1;
}

//Flushes out all dirty pages and deallocates the buffer pool and the BufDesc table.
BufMgr::~BufMgr() {

    // flush out all unwritten pages
    for (int i = 0; i < numBufs; i++) 
    {
        BufDesc* tmpbuf = &bufTable[i];
        if (tmpbuf->valid == true && tmpbuf->dirty == true) {

#ifdef DEBUGBUF
            cout << "flushing page " << tmpbuf->pageNo
                 << " from frame " << i << endl;
#endif

            tmpbuf->file->writePage(tmpbuf->pageNo, &(bufPool[i]));
        }
    }

    delete [] bufTable;
    delete [] bufPool;
}

/*
Allocates a free frame using the clock algorithm; if necessary, writing a dirty
page back to disk. Returns BUFFEREXCEEDED if all buffer frames are pinned, 
UNIXERR if the call to the I/O layer returned an error when a dirty page was 
being written to disk and OK otherwise.  This private method will get called by 
the readPage() and allocPage() methods described below.

Make sure that if the buffer frame allocated has a valid page in it, that you 
remove the appropriate entry from the hash table.

*/
const Status BufMgr::allocBuf(int & frame) 
{
    BufDesc *currptr;
    uint initPos = clockHand;
    bool bufferFull = true;
    
    while(1) {
        advanceClock();
        currptr = &bufTable[clockHand];        
        // valid Set?
        if (currptr->valid == false) {
            frame = currptr->frameNo;
            return OK;
            // Invoke Set() on Frame, Use Frame
        }
        if (currptr->refbit == true) {
            // Clear refBit
            currptr->refbit = false;
            // If page is now available, prevent BUFFEREXCEEDED
            if (currptr->pinCnt == 0) {
                bufferFull = false;
            }
            // Breaking flow chart a bit..
            // However, it makes sense to do it here instead of it's own spot
            else if (bufferFull == true && clockHand == initPos) {
                return BUFFEREXCEEDED;
            }
            continue;
        }
        if (currptr->dirty == true) {
            // Flush Page to Disk
            Status flushStatus = OK;
            flushStatus = currptr->file->writePage(currptr->pageNo,&bufPool[clockHand]);
            if (flushStatus != OK) {
                return UNIXERR;
            }
        }
        // Refbit was previously false, valid is true, and was flushed to disk
        // if necessary, Set frame to this frame, and return OK.
        frame = currptr->frameNo;
        Status removeStatus = OK;
        
        removeStatus = hashTable->remove(currptr->file, currptr->pageNo);
        if (removeStatus != OK) {
            // Not in spec???
            return BUFFEREXCEEDED;
        }
        return OK;
    }
}

/*
First check whether the page is already in the buffer pool by invoking the 
lookup() method on the hashtable to get a frame number.  There are two cases to
be handled depending on the outcome of the lookup() call:

Case 1) Page is not in the buffer pool.  Call allocBuf() to allocate a buffer 
frame and then call the method file->readPage() to read the page from disk into 
the buffer pool frame. Next, insert the page into the hashtable. Finally, invoke
Set() on the frame to set it up properly. Set() will leave the pinCnt for the 
page set to 1.  Return a pointer to the frame containing the page via the page
parameter.

Case 2)  Page is in the buffer pool.  In this case set the appropriate refbit, 
increment the pinCnt for the page, and then return a pointer to the frame 
containing the page via the page parameter.

Returns OK if no errors occurred, UNIXERR if a Unix error occurred, 
BUFFEREXCEEDED if all buffer frames are pinned, HASHTBLERROR if a hash table
error occurred.
*/
const Status BufMgr::readPage(File* file, const int PageNo, Page*& page)
{
    Status status = OK;
    int frameNo = -1;    
    // First check whether the page is already in the buffer pool by invoking the 
    // lookup() method on the hashtable to get a frame number.
    status = hashTable->lookup(file,PageNo,frameNo);
    if (status == OK)
    {
        //Page is in the buffer pool
        bufTable[frameNo].refbit = true;
        bufTable[frameNo].pinCnt = bufTable[frameNo].pinCnt + 1;
        page = &bufPool[frameNo];
        return OK;
    }
    else if (status == HASHNOTFOUND) {
        //Page is not in buffer pool. 
        Status allocStatus = OK;
        allocStatus = allocBuf(frameNo);
        if (allocStatus == OK) {
            Status readPageStatus = OK;
            readPageStatus = file->readPage(PageNo,&bufPool[frameNo]);
            if (readPageStatus == OK) {
                page = &bufPool[frameNo];
                Status insertStatus = OK;
                insertStatus = hashTable->insert(file,PageNo,frameNo);
                if (insertStatus == OK) {
                    bufTable[frameNo].Set(file,PageNo);
                    return OK;
                }
                else {
                    return HASHTBLERROR;
                }
            }
            else {
                return UNIXERR;
            }
        }
        else {
            return allocStatus;
        }
        
    }
    // catch all
    return OK;
}

/*
Decrements the pinCnt of the frame containing (file, PageNo) and, if 
dirty ==true, sets the dirty bit.  Returns OK if no errors occurred, 
HASHNOTFOUND if the page is not in the buffer pool hash table, PAGENOTPINNED 
if the pin count is already 0.
*/
const Status BufMgr::unPinPage(File* file, const int PageNo, 
			       const bool dirty) 
{
    Status status = OK;
    int frameNo = -1;
    status = hashTable->lookup(file, PageNo, frameNo);
    if (status == OK)
    {
        if (bufTable[frameNo].pinCnt <= 0) {
            return PAGENOTPINNED;
        }
        bufTable[frameNo].pinCnt = bufTable[frameNo].pinCnt - 1;
        if (dirty == true) {
            bufTable[frameNo].dirty = true;
        }
        return OK;
    }
    else if (status == HASHNOTFOUND){
        return HASHNOTFOUND;
    }
    // Catch all
    return OK;
}

/*
This call is kind of weird.  The first step is to to allocate an empty page in 
the specified file by invoking the file->allocatePage() method. This method will
return the page number of the newly allocated page.  Then allocBuf() is called 
to obtain a buffer pool frame.  Next, an entry is inserted into the hash table 
and Set() is invoked on the frame to set it up properly.  The method returns 
both the page number of the newly allocated page to the caller via the pageNo 
parameter and a pointer to the buffer frame allocated for the page via the page 
parameter. Returns OK if no errors occurred, UNIXERR if a Unix error occurred, 
BUFFEREXCEEDED if all buffer frames are pinned and HASHTBLERROR if a hash table 
error occurred. 
*/
const Status BufMgr::allocPage(File* file, int& pageNo, Page*& page) 
{
//     Status status = OK;
    Status allocPageStatus = OK;
//     Status allocBufStatus = OK;
    Status insertStatus = OK;
    // allocate an empty page in the specified file by invoking the file->allocatePage() method
    allocPageStatus = file->allocatePage(pageNo);
    if (allocPageStatus != OK) {
        return UNIXERR;
    }
    int frameNo = -1;
    // allocBuf() is called to obtain a buffer pool frame
    allocPageStatus = allocBuf(frameNo);
    if (allocPageStatus == BUFFEREXCEEDED) {
        return BUFFEREXCEEDED;
    }
    if (allocPageStatus == UNIXERR) {
        return UNIXERR;
    }
//     if (allocPageStatus == HASHTBLERROR) {
//         return HASHTBLERROR;
//     }
    // an entry is inserted into the hash table
    insertStatus = hashTable->insert(file, pageNo, frameNo);
    if (insertStatus != OK) {
        return HASHTBLERROR;
    }
    // Set() is invoked on the frame to set it up properly
    bufTable[frameNo].Set(file, pageNo);
    page = &bufPool[frameNo];
    return OK;
}

const Status BufMgr::disposePage(File* file, const int pageNo) 
{
    // see if it is in the buffer pool
    Status status = OK;
    int frameNo = 0;
    status = hashTable->lookup(file, pageNo, frameNo);
    if (status == OK)
    {
        // clear the page
        bufTable[frameNo].Clear();
    }
    status = hashTable->remove(file, pageNo);

    // deallocate it in the file
    return file->disposePage(pageNo);
}

const Status BufMgr::flushFile(const File* file) 
{
  Status status;

  for (int i = 0; i < numBufs; i++) {
    BufDesc* tmpbuf = &(bufTable[i]);
    if (tmpbuf->valid == true && tmpbuf->file == file) {

      if (tmpbuf->pinCnt > 0)
	  return PAGEPINNED;

      if (tmpbuf->dirty == true) {
#ifdef DEBUGBUF
	cout << "flushing page " << tmpbuf->pageNo
             << " from frame " << i << endl;
#endif
	if ((status = tmpbuf->file->writePage(tmpbuf->pageNo,
					      &(bufPool[i]))) != OK)
	  return status;

	tmpbuf->dirty = false;
      }

      hashTable->remove(file,tmpbuf->pageNo);

      tmpbuf->file = NULL;
      tmpbuf->pageNo = -1;
      tmpbuf->valid = false;
    }

    else if (tmpbuf->valid == false && tmpbuf->file == file)
      return BADBUFFER;
  }
  
  return OK;
}


void BufMgr::printSelf(void) 
{
    BufDesc* tmpbuf;
  
    cout << endl << "Print buffer...\n";
    for (int i=0; i<numBufs; i++) {
        tmpbuf = &(bufTable[i]);
        cout << i << "\t" << (char*)(&bufPool[i]) 
             << "\tpinCnt: " << tmpbuf->pinCnt;
    
        if (tmpbuf->valid == true)
            cout << "\tvalid\n";
        cout << endl;
    };
}


