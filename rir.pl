#!/usr/bin/env perl
#
# This takes a simplified version of iana address space registry at
# http://www.iana.org/assignments/ipv4-address-space/ipv4-address-space.txt
# (found in the DATA block below) and renders a simple, consolidated version
# of it sufficient to possibly use in an antispam fashion.
# 

use 5.10.0;

use strict;
use warnings;

use NetAddr::IP qw/Compact/;
use Data::Dumper::Names;


my @RIRs = qw[
    ARIN
    RIPE
    APNIC
    AFRINIC
    LACNIC
    OTHER
    ];

my $table  = {};
my $lists  = {};

for ( <DATA> ) {

    chomp;

    my ( $ipcidr, $rir ) = split /\s+/;

    unless ( $rir ~~ @RIRs ) {
        warn "Error, bad rir: ${rir}\n";
        sleep 1;
        next;
    }

    my $ip = NetAddr::IP->new($ipcidr);

    $table->{$rir}->{$ipcidr} = $ip;

}


for my $curnic ( keys %$table ) {

    # Schwartzian Transform FTW!
    #
    push @{ $lists->{$curnic} }, $_ for 
        map  { "${curnic} $_->[1]" }
        sort { $a->[0] <=> $b->[0] }
        map  {
                my $string =
                      $_->version == 6
                    ? $_->short . '/' . $_->masklen
                    : $_->cidr;
                [ $_->masklen, $string ];

             } collapser( $table->{$curnic} );

}


for my $currir ( sort keys %$lists ) {
    print "$_\n" for @{ $lists->{$currir} };
}


sub collapser {

    my $tab    = shift;
    my @blocks = keys %$tab;

    my @objs;

    for (@blocks) {
        my $curobj = $tab->{$_};
        push @objs, $curobj;

    }

    my @collapsed = Compact(@objs);

    return wantarray ? @collapsed : \@collapsed;

}


__DATA__
1/8  APNIC
2/8  RIPE
3/8  ARIN
4/8  ARIN
5/8  RIPE
6/8  OTHER
7/8  ARIN
8/8  ARIN
9/8  ARIN
11/8  OTHER
12/8  ARIN
13/8  ARIN
14/8  APNIC
15/8  ARIN
16/8  ARIN
17/8  ARIN
18/8  ARIN
19/8  ARIN
20/8  ARIN
21/8  OTHER
22/8  OTHER
23/8  ARIN
24/8  ARIN
25/8  RIPE
26/8  OTHER
27/8  APNIC
28/8  OTHER
29/8  OTHER
30/8  OTHER
31/8  RIPE
32/8  ARIN
33/8  OTHER
34/8  ARIN
35/8  ARIN
36/8  APNIC
37/8  RIPE
38/8  ARIN
39/8  APNIC
40/8  ARIN
41/8  AFRINIC
42/8  APNIC
43/8  APNIC
44/8  ARIN
45/8  ARIN
46/8  RIPE
47/8  ARIN
48/8  ARIN
49/8  APNIC
50/8  ARIN
51/8  RIPE
52/8  ARIN
53/8  OTHER
54/8  ARIN
55/8  OTHER
56/8  ARIN
57/8  OTHER
58/8  APNIC
59/8  APNIC
60/8  APNIC
61/8  APNIC
62/8  RIPE
63/8  ARIN
64/8  ARIN
65/8  ARIN
66/8  ARIN
67/8  ARIN
68/8  ARIN
69/8  ARIN
70/8  ARIN
71/8  ARIN
72/8  ARIN
73/8  ARIN
74/8  ARIN
75/8  ARIN
76/8  ARIN
77/8  RIPE
78/8  RIPE
79/8  RIPE
80/8  RIPE
81/8  RIPE
82/8  RIPE
83/8  RIPE
84/8  RIPE
85/8  RIPE
86/8  RIPE
87/8  RIPE
88/8  RIPE
89/8  RIPE
90/8  RIPE
91/8  RIPE
92/8  RIPE
93/8  RIPE
94/8  RIPE
95/8  RIPE
96/8  ARIN
97/8  ARIN
98/8  ARIN
99/8  ARIN
100/8  ARIN
101/8  APNIC
102/8  AFRINIC
103/8  APNIC
104/8  ARIN
105/8  AFRINIC
106/8  APNIC
107/8  ARIN
108/8  ARIN
109/8  RIPE
110/8  APNIC
111/8  APNIC
112/8  APNIC
113/8  APNIC
114/8  APNIC
115/8  APNIC
116/8  APNIC
117/8  APNIC
118/8  APNIC
119/8  APNIC
120/8  APNIC
121/8  APNIC
122/8  APNIC
123/8  APNIC
124/8  APNIC
125/8  APNIC
126/8  APNIC
128/8  ARIN
129/8  ARIN
130/8  ARIN
131/8  ARIN
132/8  ARIN
133/8  APNIC
134/8  ARIN
135/8  ARIN
136/8  ARIN
137/8  ARIN
138/8  ARIN
139/8  ARIN
140/8  ARIN
141/8  RIPE
142/8  ARIN
143/8  ARIN
144/8  ARIN
145/8  RIPE
146/8  ARIN
147/8  ARIN
148/8  ARIN
149/8  ARIN
150/8  APNIC
151/8  RIPE
152/8  ARIN
153/8  APNIC
154/8  AFRINIC
155/8  ARIN
156/8  ARIN
157/8  ARIN
158/8  ARIN
159/8  ARIN
160/8  ARIN
161/8  ARIN
162/8  ARIN
163/8  APNIC
164/8  ARIN
165/8  ARIN
166/8  ARIN
167/8  ARIN
168/8  ARIN
169/8  ARIN
170/8  ARIN
171/8  APNIC
172/8  ARIN
173/8  ARIN
174/8  ARIN
175/8  APNIC
176/8  RIPE
177/8  LACNIC
178/8  RIPE
179/8  LACNIC
180/8  APNIC
181/8  LACNIC
182/8  APNIC
183/8  APNIC
184/8  ARIN
185/8  RIPE
186/8  LACNIC
187/8  LACNIC
188/8  RIPE
189/8  LACNIC
190/8  LACNIC
191/8  LACNIC
192/8  ARIN
193/8  RIPE
194/8  RIPE
195/8  RIPE
196/8  AFRINIC
197/8  AFRINIC
198/8  ARIN
199/8  ARIN
200/8  LACNIC
201/8  LACNIC
202/8  APNIC
203/8  APNIC
204/8  ARIN
205/8  ARIN
206/8  ARIN
207/8  ARIN
208/8  ARIN
209/8  ARIN
210/8  APNIC
211/8  APNIC
212/8  RIPE
213/8  RIPE
214/8  OTHER
215/8  OTHER
216/8  ARIN
217/8  RIPE
218/8  APNIC
219/8  APNIC
220/8  APNIC
221/8  APNIC
222/8  APNIC
223/8  APNIC
2001:0000::/23  OTHER
2001:0200::/23  APNIC
2001:0400::/23  ARIN
2001:0600::/23  RIPE
2001:0800::/23  RIPE
2001:0a00::/23  RIPE
2001:0c00::/23  APNIC
2001:0e00::/23  APNIC
2001:1200::/23  LACNIC
2001:1400::/23  RIPE
2001:1600::/23  RIPE
2001:1800::/23  ARIN
2001:1a00::/23  RIPE
2001:1c00::/22  RIPE
2001:2000::/20  RIPE
2001:3000::/21  RIPE
2001:3800::/22  RIPE
2001:3c00::/22  OTHER
2001:4000::/23  RIPE
2001:4200::/23  AFRINIC
2001:4400::/23  APNIC
2001:4600::/23  RIPE
2001:4800::/23  ARIN
2001:4a00::/23  RIPE
2001:4c00::/23  RIPE
2001:5000::/20  RIPE
2001:8000::/19  APNIC
2001:a000::/20  APNIC
2001:b000::/20  APNIC
2002:0000::/16  OTHER
2003:0000::/18  RIPE
2400:0000::/12  APNIC
2600:0000::/12  ARIN
2610:0000::/23  ARIN
2620:0000::/23  ARIN
2800:0000::/12  LACNIC
2a00:0000::/12  RIPE
2c00:0000::/12  AFRINIC
2d00:0000::/8   OTHER
2e00:0000::/7   OTHER
3000:0000::/4   OTHER
3ffe::/16   OTHER
5f00::/8    OTHER
