#include "ruby.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/rfcomm.h>
#include <bluetooth/hci.h>

////////////////////////////////////////////////////////////////////////////////
// Local types

VALUE mindset_module;
VALUE mindset_class;

////////////////////////////////////////////////////////////////////////////////
// Forward Declarations

static VALUE mindset_initialize(VALUE);
static VALUE mindset_listen(VALUE, VALUE, VALUE);
static VALUE mindset_open(VALUE, VALUE, VALUE);
static VALUE mindset_read(VALUE);
static VALUE mindset_close(VALUE);
static VALUE mindset_scan(VALUE);

////////////////////////////////////////////////////////////////////////////////
// Initialization

/*
 * Class to connect to and read the data stream of a mindset headset
 */
void Init_mindset_device()
{
    // Define the Mindset module
    mindset_module = rb_define_module("Mindset");

    // Define the Device class
    mindset_class = rb_define_class_under(mindset_module, "Device", rb_cObject);
    rb_define_method(mindset_class, "initialize", mindset_initialize, 0);
    rb_define_method(mindset_class, "listen", mindset_listen, 2);
    rb_define_method(mindset_class, "open", mindset_open, 2);
    rb_define_method(mindset_class, "read", mindset_read, 0);
    rb_define_method(mindset_class, "close", mindset_close, 0);
    rb_define_singleton_method(mindset_class, "scan", mindset_scan, 0);
}

////////////////////////////////////////////////////////////////////////////////
// Mindset class

// NOTE: I want to yield and close() at the end of the block - This is possible
// will need some thought - NOT important at present as any changes only impact
// a small part of the "API"
/*
 * Returns a new array that is a one-dimensional flattening of this
 * array (recursively). That is, for every element that is an array,
 * extract its elements into the new array.
 *
 *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
 *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
 *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
 *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 */
static VALUE mindset_initialize(VALUE self)
{
    VALUE s = rb_iv_set(self, "@socket", 0);
    return self;
}


// Preferred method - As the block will close the socket automatically
/*
 * Returns a new array that is a one-dimensional flattening of this
 * array (recursively). That is, for every element that is an array,
 * extract its elements into the new array.
 *
 *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
 *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
 *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
 *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 */
static VALUE mindset_listen(VALUE self, VALUE r_address, VALUE r_channel)
{
    if (rb_block_given_p() > 0) {
        mindset_close(self);
        mindset_open(self, r_address, r_channel);
        rb_yield(self);
        mindset_close(self);
    }
    return Qnil;
}

/*
 * Returns a new array that is a one-dimensional flattening of this
 * array (recursively). That is, for every element that is an array,
 * extract its elements into the new array.
 *
 *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
 *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
 *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
 *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 */
static VALUE mindset_open(VALUE self, VALUE r_address, VALUE r_channel)
{
    mindset_close(self);

    // Todo - type checks???
    struct sockaddr_rc addr;
    int s;
    const char* address = STR2CSTR(r_address);
    int   channel = NUM2INT(r_channel);

    addr.rc_family = AF_BLUETOOTH;
    addr.rc_channel = (uint8_t) channel;
    str2ba(address, &addr.rc_bdaddr);

    s = socket(AF_BLUETOOTH, SOCK_STREAM, BTPROTO_RFCOMM);
    rb_iv_set(self, "@socket", s);

    if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        mindset_close(self);
        rb_sys_fail("connect");
    }

    return Qnil;
}

/*
 * Returns a new array that is a one-dimensional flattening of this
 * array (recursively). That is, for every element that is an array,
 * extract its elements into the new array.
 *
 *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
 *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
 *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
 *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 */
static VALUE mindset_read(VALUE self)
{
    VALUE s = rb_iv_get(self, "@socket");
    if (s != 0) {
        char buf[1024] = { 0 };
        int i;
        VALUE result = rb_ary_new();
        VALUE s = rb_iv_get(self, "@socket");
        int bytes_read = read(s, buf, sizeof(buf));
    
        for(i = 0; i < bytes_read; i++) {
            rb_ary_push(result, CHR2FIX(buf[i]));
        }
        return result;
    } else {
        rb_raise(rb_eRuntimeError, "device not opened");
    }
}

/*
 * call-seq:
 *   obj.method(required, optional=0) -> retval
 *
 * Call +wrappedLibraryFunction
 * +[http://www.example.org/docs.html#wrappedLibraryFunction]
 * to execute wrappedLibraryFunction.  This method takes a
 * single required argument, and one optional argument that
 * defaults to 0 if not specified.  It returns retval, which
 * can be any valid ruby object
 */
static VALUE mindset_close(VALUE self)
{
    VALUE s = rb_iv_get(self, "@socket");
    if (s != 0) {
        rb_iv_set(self, "@socket", 0);
        close(s);
    }
    return Qnil;
}

/*
 * Returns a new array that is a one-dimensional flattening of this
 * array (recursively). That is, for every element that is an array,
 * extract its elements into the new array.
 *
 *    s = [ 1, 2, 3 ]           #=> [1, 2, 3]
 *    t = [ 4, 5, 6, [7, 8] ]   #=> [4, 5, 6, [7, 8]]
 *    a = [ s, t, 9, 10 ]       #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
 *    a.flatten                 #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
 */
static VALUE mindset_scan(VALUE self)
{
    VALUE array, addr_name_info;
    inquiry_info *ii = NULL;
    int max_rsp, num_rsp;
    int dev_id, sock, len, flags;
    int i;
    char addr[19] = { 0 };
    char name[248] = { 0 };

    dev_id = hci_get_route(NULL);

    sock = hci_open_dev( dev_id );
    if (dev_id < 0 || sock < 0) {
        rb_sys_fail("opening socket");
        return Qnil;
    }
    
    array = rb_ary_new();
    len  = 8;
    max_rsp = 255;
    flags = IREQ_CACHE_FLUSH;
    ii = (inquiry_info*) malloc(max_rsp * sizeof(inquiry_info));
    
    num_rsp = hci_inquiry(dev_id, len, max_rsp, NULL, &ii, flags);

    for (i = 0; i < num_rsp; i++) {
        ba2str(&(ii+i)->bdaddr, addr);
        memset(name, 0, sizeof(name));
        if (hci_read_remote_name(sock, &(ii+i)->bdaddr, sizeof(name), name, 0) < 0) {
            strcpy(name, "[unknown]");
        }
        addr_name_info = rb_ary_new();
        rb_ary_push(addr_name_info, rb_str_new2(addr));
        rb_ary_push(addr_name_info, rb_str_new2(name));
        rb_ary_push(array, addr_name_info);
    }

    free(ii);
    close(sock);
    
    return array;
}

////////////////////////////////////////////////////////////////////////////////
