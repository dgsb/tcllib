# sha1c.tcl - 
#
# Wrapper for the Secure Hashing Algorithm (SHA1)
#
# * SHA-1 in C
# * By Steve Reid <steve@edmweb.com>
# * 100% Public Domain
#
#
# $Id: sha1c.tcl,v 1.1 2005/02/20 22:58:58 patthoyts Exp $

package require critcl;                 # needs critcl
package provide sha1c 2.0.0;            # 

critcl::cheaders sample.h;              # The Tcl sample extension SHA1 header
critcl::csources sample.c;              # The Tcl sample extension SHA1 C file

namespace eval ::sha1 {

    critcl::ccode {
        #include "sample.h"
        #include <malloc.h>
        #include <memory.h>
        #include <assert.h>
        
        static
        Tcl_ObjType sha1_type; /* fast internal access representation */
        
        static void 
        sha1_free_rep(Tcl_Obj* obj)
        {
            SHA1_CTX* mp = (SHA1_CTX*) obj->internalRep.otherValuePtr;
            free(mp);
        }
        
        static void
        sha1_dup_rep(Tcl_Obj* obj, Tcl_Obj* dup)
        {
            SHA1_CTX* mp = (SHA1_CTX*) obj->internalRep.otherValuePtr;
            dup->internalRep.otherValuePtr = malloc(sizeof *mp);
            memcpy(dup->internalRep.otherValuePtr, mp, sizeof *mp);
            dup->typePtr = &sha1_type;
        }
        
        static void
        sha1_string_rep(Tcl_Obj* obj)
        {
            unsigned char buf[20];
            Tcl_Obj* temp;
            char* str;
            SHA1_CTX dup = *(SHA1_CTX*) obj->internalRep.otherValuePtr;
            
            SHA1Final(&dup, buf);
            
            /* convert via a byte array to properly handle null bytes */
            temp = Tcl_NewByteArrayObj(buf, sizeof buf);
            Tcl_IncrRefCount(temp);
            
            str = Tcl_GetStringFromObj(temp, &obj->length);
            obj->bytes = Tcl_Alloc(obj->length + 1);
            memcpy(obj->bytes, str, obj->length + 1);
            
            Tcl_DecrRefCount(temp);
        }
        
        static int
        sha1_from_any(Tcl_Interp* ip, Tcl_Obj* obj)
        {
            assert(0);
            return TCL_ERROR;
        }
        
        static
        Tcl_ObjType sha1_type = {
            "sha1c", sha1_free_rep, sha1_dup_rep, sha1_string_rep,
            sha1_from_any
        };
    }
    
    critcl::ccommand sha1c {dummy ip objc objv} {
        SHA1_CTX* mp;
        unsigned char* data;
        int size;
        Tcl_Obj* obj;
        
        if (objc < 2 || objc > 3) {
            Tcl_WrongNumArgs(ip, 1, objv, "data ?context?");
            return TCL_ERROR;
        }
        
        if (objc == 3) {
            if (objv[2]->typePtr != &sha1_type 
                && sha1_from_any(ip, objv[2]) != TCL_OK)
            return TCL_ERROR;
            obj = objv[2];
            if (Tcl_IsShared(obj))
            obj = Tcl_DuplicateObj(obj);
        } else {
            obj = Tcl_NewObj();
            mp = (SHA1_CTX*) malloc(sizeof *mp);
            SHA1Init(mp);
            
            if (obj->typePtr != NULL && obj->typePtr->freeIntRepProc != NULL)
            obj->typePtr->freeIntRepProc(obj);
            
            obj->internalRep.otherValuePtr = mp;
            obj->typePtr = &sha1_type;
        }
        
        Tcl_SetObjResult(ip, obj);
        Tcl_IncrRefCount(obj); //!! huh?
        
        Tcl_InvalidateStringRep(obj);
        mp = (SHA1_CTX*) obj->internalRep.otherValuePtr;
        
        data = Tcl_GetByteArrayFromObj(objv[1], &size);
        SHA1Update(mp, data, size);
        
        return TCL_OK;
    }
}
